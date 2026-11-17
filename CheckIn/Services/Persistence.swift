import Foundation
import SwiftUI
internal import Combine



enum Persistence {
    private static func url(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(name).json")
    }
    static func load<T: Codable>(_ name: String) -> [T] {
        guard let data = try? Data(contentsOf: url(name)),
              let items = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return items
    }
    static func save<T: Codable>(_ items: [T], as name: String) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url(name), options: .atomic)
        }
    }
}

// new models the protocols need

/// Links a student to a course (Course alone can't answer "which courses is this user in?").
struct Enrollment: Codable, Identifiable {
    let id: String
    let userID: String
    let courseID: String
}

/// Remembers who upvoted what, so toggling works and nobody can upvote twice.
struct UpvoteRecord: Codable {
    let feedbackID: String
    let userID: String
}

enum ServiceError: LocalizedError {
    case notSignedIn, wrongRole, notFound, alreadyEnrolled, rejected(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:        return "You need to sign in first."
        case .wrongRole:          return "Your account type can't do that."
        case .notFound:           return "That item couldn't be found."
        case .alreadyEnrolled:    return "You're already in this course."
        case .rejected(let why):  return why
        }
    }
}

// current user? (services need this)

protocol SessionProvider {
    var currentUser: User? { get }
}

// Stores: keep your classes, but (a) unique filenames, (b) a mutate hook

// Enrollments: links students to courses (same pattern as the other stores).

final class Enrollments: ObservableObject {
    @Published var items: [Enrollment] = []
    private let fileName = "enrollments"
    init() { items = Persistence.load(fileName) }

    func add(userID: String, courseID: String) {
        items.append(Enrollment(id: UUID().uuidString, userID: userID, courseID: courseID))
        Persistence.save(items, as: fileName)
    }
}

//  Local implementations of the protocols

//ModerationService (no dependencies, used by the feedback service)

struct LocalModerationService: ModerationService {
    // Replace with a real classifier / server-side check later.
    private let blocked = ["idiot", "stupid", "hate you", "kill"]

    func validate(_ text: String) -> ModerationResult {
        let lower = text.lowercased()
        if blocked.contains(where: lower.contains) {
            return .rejected(reason: "Please keep feedback respectful and constructive.")
        }
        return .approved
    }
}

// CourseService

@MainActor
final class LocalCourseService: CourseService {
    private let courseStore: CourseProfessors
    private let enrollments: Enrollments
    private let session: SessionProvider

    init(courseStore: CourseProfessors, enrollments: Enrollments, session: SessionProvider) {
        self.courseStore = courseStore
        self.enrollments = enrollments
        self.session = session
    }

    func createCourse(name: String) async throws -> Course {
        guard let user = session.currentUser else { throw ServiceError.notSignedIn }
        guard user.role == .professor else { throw ServiceError.wrongRole }
        let code = makeUniqueCode()
        courseStore.addCourse(name: name, code: code, professorID: user.id, professorName: user.name)
        guard let course = courseStore.courses.last else { throw ServiceError.notFound }
        return course
    }

    func joinCourse(code: String) async throws -> Course {
        guard let user = session.currentUser else { throw ServiceError.notSignedIn }
        let key = code.trimmingCharacters(in: .whitespaces).uppercased()
        guard let course = courseStore.courses.first(where: { $0.joinCode.uppercased() == key })
        else { throw ServiceError.notFound }
        guard !enrollments.items.contains(where: { $0.userID == user.id && $0.courseID == course.id })
        else { throw ServiceError.alreadyEnrolled }
        enrollments.add(userID: user.id, courseID: course.id)
        return course
    }

    func courses(for user: User) async throws -> [Course] {
        if user.role == .professor {
            return courseStore.courses.filter { $0.professorID == user.id }
        }
        let ids = Set(enrollments.items.filter { $0.userID == user.id }.map(\.courseID))
        return courseStore.courses.filter { ids.contains($0.id) }
    }

    private func makeUniqueCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        while true {
            let code = String((0..<6).map { _ in chars.randomElement()! })
            if !courseStore.courses.contains(where: { $0.joinCode == code }) { return code }
        }
    }
}

//FeedbackService

@MainActor
final class LocalFeedbackService: FeedbackService {
    private let store: Feedbacks
    private let moderation: ModerationService
    private let session: SessionProvider
    private var upvotes: [UpvoteRecord] = Persistence.load("upvotes")

    init(store: Feedbacks, moderation: ModerationService, session: SessionProvider) {
        self.store = store
        self.moderation = moderation
        self.session = session
    }

    func submit(courseID: String, category: FeedbackCategory, comment: String) async throws {
        guard session.currentUser != nil else { throw ServiceError.notSignedIn }
        try check(comment)
        store.addFeed(courseID: courseID, category: category, comment: comment,
                      upVote: 0, status: .open)   // adjust to your FeedbackStatus initial case
    }

    func feedback(for courseID: String) async throws -> [Feedback] {
        store.Feed
            .filter { $0.courseID == courseID }
            .sorted { $0.upvoteCount > $1.upvoteCount }
    }

    func toggleUpvote(feedbackID: String) async throws {
        guard let user = session.currentUser else { throw ServiceError.notSignedIn }
        let already = upvotes.contains { $0.feedbackID == feedbackID && $0.userID == user.id }
        if already {
            upvotes.removeAll { $0.feedbackID == feedbackID && $0.userID == user.id }
        } else {
            upvotes.append(UpvoteRecord(feedbackID: feedbackID, userID: user.id))
        }
        Persistence.save(upvotes, as: "upvotes")
        try edit(feedbackID) { $0.upvoteCount += already ? -1 : 1 }
    }

    func reply(feedbackID: String, text: String) async throws {
        guard let user = session.currentUser else { throw ServiceError.notSignedIn }
        guard user.role == .professor else { throw ServiceError.wrongRole }
        try check(text)
        try edit(feedbackID) { $0.professorReply = text }
    }

    func setStatus(feedbackID: String, status: FeedbackStatus) async throws {
        guard session.currentUser?.role == .professor else { throw ServiceError.wrongRole }
        try edit(feedbackID) { $0.status = status }
    }

    // helpers
    private func check(_ text: String) throws {
        if case .rejected(let reason) = moderation.validate(text) {
            throw ServiceError.rejected(reason)
        }
    }

    private func edit(_ id: String, _ change: (inout Feedback) -> Void) throws {
        guard store.Feed.contains(where: { $0.id == id }) else { throw ServiceError.notFound }
        store.mutate { items in
            if let i = items.firstIndex(where: { $0.id == id }) { change(&items[i]) }
        }
    }
}

// CheckInService

@MainActor
final class LocalCheckInService: CheckInService {
    private let store: CheckIns

    init(store: CheckIns) { self.store = store }

    func submit(courseID: String, checkIn: CheckIn) async throws {
        store.add(checkIn)
    }

    func trend(for courseID: String) async throws -> [RatingTrendPoint] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: store.checks.filter { $0.courseID == courseID }) {
            cal.startOfDay(for: $0.date)
        }
        return byDay
            .map { day, items in
                RatingTrendPoint(date: day,
                                 average: Double(items.map(\.rating).reduce(0, +)) / Double(items.count))
            }
            .sorted { $0.date < $1.date }
    }
}

//  implementations the app uses

@MainActor
final class AppEnvironment: ObservableObject, SessionProvider {
    @Published var currentUser: User?

    // Stores (local persistence)
    let users = StudentsUsers()
    let courseStore = CourseProfessors()
    let enrollments = Enrollments()
    let checkInStore = CheckIns()
    let feedbackStore = Feedbacks()

    // Services (views only ever see these protocol types)
    let courses: CourseService
    let feedback: FeedbackService
    let checkIns: CheckInService
    let moderation: ModerationService

    // Replace with your real university values and backend.
    let auth: AuthService = UniversitySSOAuthService(
        authorizeURL: URL(string: "https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize")!,
        clientID: "YOUR_CLIENT_ID",
        callbackScheme: "checkin",
        backend: PlaceholderIdentityBackend())

    init() {
        let moderation = LocalModerationService()
        self.moderation = moderation
        // `self` isn't fully initialized yet, so give services a lightweight session box
        let box = SessionBox()
        self.sessionBox = box
        courses = LocalCourseService(courseStore: courseStore, enrollments: enrollments, session: box)
        feedback = LocalFeedbackService(store: feedbackStore, moderation: moderation, session: box)
        checkIns = LocalCheckInService(store: checkInStore)
    }

    private let sessionBox: SessionBox

    func signIn(_ user: User) { currentUser = user; sessionBox.currentUser = user }

    func signIn(using auth: AuthService, authenticate: WebAuthenticate) async throws {
        signIn(try await auth.signIn(authenticate: authenticate))
    }
    func signOut() { currentUser = nil; sessionBox.currentUser = nil }
}

final class SessionBox: SessionProvider {
    var currentUser: User?
}

// Using from a view model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var errorMessage: String?

    private let service: CourseService
    private let user: User

    init(service: CourseService, user: User) {
        self.service = service
        self.user = user
    }

    func load() async {
        do { courses = try await service.courses(for: user) }
        catch { errorMessage = error.localizedDescription }
    }

    @discardableResult
    func join(code: String) async -> Bool {
        errorMessage = nil
        do {
            _ = try await service.joinCourse(code: code)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

