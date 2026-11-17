import Foundation
import SwiftUI
internal import Combine

// Persistence (the enum) and Enrollments live in Services.swift.
// Each store now saves to its own file, so they no longer overwrite each other.

class StudentsUsers: ObservableObject {
    @Published var users: [User] = []
    private let fileName = "users"

    init() {
        users = Persistence.load(fileName)
    }

    func addUser(name: String, role: UserRole) {
        let newUser = User(id: UUID().uuidString, name: name, role: role)
        users.append(newUser)
        save()
    }

    func deleteUsers(at offsets: IndexSet) {
        users.remove(atOffsets: offsets)
        save()
    }

    private func save() { Persistence.save(users, as: fileName) }
}


class CourseProfessors: ObservableObject {
    @Published var courses: [Course] = []
    private let fileName = "courses"

    init() {
        courses = Persistence.load(fileName)
    }

    func addCourse(name: String, code: String, professorID: String, professorName: String = "") {
        let newCourse = Course(id: UUID().uuidString, name: name, joinCode: code,
                            professorID: professorID, professorName: professorName)
        courses.append(newCourse)
        save()
    }

    func deleteCourse(at offsets: IndexSet) {
        courses.remove(atOffsets: offsets)
        save()
    }

    /// Lets services edit existing courses and persist the result.
    func mutate(_ change: (inout [Course]) -> Void) {
        change(&courses)
        save()
    }

    private func save() { Persistence.save(courses, as: fileName) }
}


class CheckIns: ObservableObject {
    @Published var checks: [CheckIn] = []
    private let fileName = "checkins"

    init() {
        checks = Persistence.load(fileName)
    }

    func addCheckin(courseID: String, rating: Int) {
        let newCheck = CheckIn(id: UUID().uuidString, courseID: courseID, rating: rating, date: Date())
        add(newCheck)
    }

    /// Used by CheckInService, which is handed a ready-made CheckIn.
    func add(_ checkIn: CheckIn) {
        checks.append(checkIn)
        save()
    }

    func deleteCheckIn(at offsets: IndexSet) {
        checks.remove(atOffsets: offsets)
        save()
    }

    private func save() { Persistence.save(checks, as: fileName) }
}


class Feedbacks: ObservableObject {
    @Published var Feed: [Feedback] = []
    private let fileName = "feedback"

    init() {
        Feed = Persistence.load(fileName)
    }

    func addFeed(courseID: String, category: FeedbackCategory, comment: String, upVote: Int, status: FeedbackStatus) {
        let newFeed = Feedback(id: UUID().uuidString, courseID: courseID, category: category,
                               comment: comment, upvoteCount: upVote, status: status,
                               professorReply: nil, createdAt: Date())
        Feed.append(newFeed)
        save()
    }

    func deleteFeed(at offsets: IndexSet) {
        Feed.remove(atOffsets: offsets)
        save()
    }

    /// Lets FeedbackService change upvotes, replies and status, then persist.
    func mutate(_ change: (inout [Feedback]) -> Void) {
        change(&Feed)
        save()
    }

    private func save() { Persistence.save(Feed, as: fileName) }
}
