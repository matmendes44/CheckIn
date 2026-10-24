//  Protocols.swift
//  CheckIn
//
//  Created by Matheus Mendes on 10/23/26.
//

enum ModerationResult {
    case approved, flagged(reason: String)
}

///Manages the users sessions, authentication, and state
protocol AuthService {
    var currentUser: User? { get }
    func signIn(email: String, password: String) async throws -> User
    func signOut() throws
}

/// Handles classroom management and enrollment from different users
protocol CourseService {
    func createCourse(name: String) async throws -> Course  //  professors course creation
    func joinCourse(code: String) async throws -> Course    //  students enrollment
    func courses(for user: User) async throws -> [Course]   //  fetches all courses associated with the user
}

///Manages core feedback loop between different users
protocol FeedbackService {
    func submit(courseID: String, category: FeedbackCategory, comment: String) async throws
    func feedback(for courseID: String) async throws -> [Feedback] //sorted by upvotes
    func toggleUpvote(feedbackID: String) async throws
    func reply (feedbackID: String, text: String) async throws      //professors reply
    func setStatus(feedbackID: String, status: FeedbackStatus) async throws
}

///Handles the check in pop up and tracks class rating over time into data points (RatingTrendPoint)
protocol CheckInService {
    func submit(courseID: String, checkIn: CheckIn) async throws
    func trend(for courseID: String) async throws -> [RatingTrendPoint]
}

///Moderation service that protects against inappropriate feedback
protocol ModerationService {
    func validate(_ text: String) -> ModerationResult      //checks user input scanning for harm.
}


