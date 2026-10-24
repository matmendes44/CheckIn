
//  MockServicesMinimal.swift
//  FeedbackApp: Services/Mock
//
//  Minimal mocks so ViewModel and View work can start right away.
//  Every method returns hardcoded data and nothing is saved.
//
//  AI GENERATION DISCLOSURE
//  LLM model used: Claude Sonnet 5.5 (Anthropic), via the Claude app
//  Date generated: October 23, 2026
//  Prompts used (verbatim):
//   1. "Create mock data with these customer data types and protocols, allowing
//       team members to test against a mock database. in the comments of the file
//       State the LLM model in use and the prompt used to product the result"
//   2. "give me a minimized version so my teammates can get started"
//
//  NOTE: Do not add this file together with MockServices.swift. They define the
//  same type names. Use one or the other.
//

import Foundation

// MARK: - Sample data

enum MockData {
    static let student = User(id: "student-1", name: "Sam Student", role: .student)
    static let professor = User(id: "prof-1", name: "Professor Demo", role: .professor)

    static let course = Course(id: "course-1", name: "COSC 435 Mobile Apps",
                               joinCode: "MOB435", professorID: "prof-1")

    static let feedback: [Feedback] = [
        Feedback(id: "fb-1", courseID: "course-1", category: .volume,
                 comment: "Could you speak up a bit? Hard to hear in the back.",
                 upvoteCount: 14, status: .acknowledged,
                 professorReply: "Thanks, I'll use the mic.", createdAt: Date()),
        Feedback(id: "fb-2", courseID: "course-1", category: .examples,
                 comment: "More worked examples before the assignment would help.",
                 upvoteCount: 9, status: .inProgress, professorReply: nil, createdAt: Date()),
        Feedback(id: "fb-3", courseID: "course-1", category: .pace,
                 comment: "SwiftUI lectures move too quickly.",
                 upvoteCount: 4, status: .open, professorReply: nil, createdAt: Date()),
    ]

    static let trend: [RatingTrendPoint] = (0..<6).map { week in
        RatingTrendPoint(date: Date().addingTimeInterval(Double(week - 5) * 7 * 86_400),
                         average: 3.0 + Double(week) * 0.35)
    }
}

// MARK: - Mock services

final class MockAuthService: AuthService {
    var currentUser: User? = MockData.student   // starts signed in; change to .professor to test that side

    func signIn(email: String, password: String) async throws -> User {
        let user = email.hasPrefix("prof") ? MockData.professor : MockData.student
        currentUser = user
        return user
    }

    func signOut() throws { currentUser = nil }
}

struct MockCourseService: CourseService {
    func createCourse(name: String) async throws -> Course { MockData.course }
    func joinCourse(code: String) async throws -> Course { MockData.course }
    func courses(for user: User) async throws -> [Course] { [MockData.course] }
}

struct MockFeedbackService: FeedbackService {
    func submit(courseID: String, category: FeedbackCategory, comment: String) async throws {}
    func feedback(for courseId: String) async throws -> [Feedback] { MockData.feedback }
    func toggleUpvote(feedbackID: String) async throws {}
    func reply(feedbackID: String, text: String) async throws {}
    func setStatus(feedbackID: String, status: FeedbackStatus) async throws {}
}

struct MockCheckInService: CheckInService {
    func submit(courseID: String, checkIn: CheckIn) async throws {}
    func trend(for courseID: String) async throws -> [RatingTrendPoint] { MockData.trend }
}

struct MockModerationService: ModerationService {
    func validate(_ text: String) -> ModerationResult { .approved }
}
