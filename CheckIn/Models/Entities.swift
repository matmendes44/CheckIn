//  Entities.swift
//  CheckIn
//
//  Created by Matheus Mendes on 10/23/26.
//

import Foundation

enum UserRole: String, Codable {
    case student
    case professor
}

enum FeedbackCategory: String, Codable, CaseIterable {
    case pace, clarity, volume, examples, materials, assignments
}

enum FeedbackStatus: String, Codable {
    case open, acknowledged, inProgress, done
}

///The user who is logged in. Role defines if they are student or professor.
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var role: UserRole
}

///This is an active course.
/// - Join code allows students to enroll.
/// - Professor ID links the course to the professor.
struct Course: Identifiable, Codable {
    let id: String
    var name: String
    var joinCode: String
    var professorID: String
}

///The anonymous feedback.
/// - Feedback Category, courseID, createdAt, and ID never change so they're let
struct Feedback: Identifiable, Codable {
    //No User name to ID post for anonimity
    let id: String
    let courseID: String
    var category: FeedbackCategory
    var comment: String
    var upvoteCount: Int
    var status: FeedbackStatus
    var professorReply: String?
    let createdAt: Date
}

///The quick how was class summary pop up
struct CheckIn: Identifiable, Codable {
    let id: String
    let courseID: String
    let rating: Int     //I was thinking 1..5 but we could do other options
    let date: Date
}


struct CategorySummary { let category: FeedbackCategory; let items: [Feedback]}

struct RatingTrendPoint { let date: Date; let average: Double}
