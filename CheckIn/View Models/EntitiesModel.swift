//
//  EntitiesModel.swift
//  CheckIn
//
//  Created by Franklin Atika on 10/29/26.
//

import Foundation
import SwiftUI
internal import Combine

//Class for each of the struct entities
//Each have thier own Add and Delete func
class StudentsUsers: ObservableObject {
    @Published var users: [User] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("tasks.json")
    
     init() {
        load()
    }
    
    func addUser(name: String, role: UserRole){
        let newUser = User(id: UUID().uuidString, name: name, role: role)
        users.append(newUser)
        save()
    }
    
    func deleteUsers(at offsets: IndexSet){
        users.remove(atOffsets: offsets)
        save()
    }
    
    // Storage
    private func save() {
        if let data = try? JSONEncoder().encode(users) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([User].self, from: data) {
            users = saved
        }
    }
    
    
}


class CourseProfessors: ObservableObject{
    
    @Published var courses: [Course] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("tasks.json")
    
    init() {
       load()
   }
    
    func addCourse(name: String, code: String, professorID: String){
        let newCourse = Course(id: UUID().uuidString, name: name, joinCode: code, professorID: professorID)
        courses.append(newCourse)
        save()
    }
    
    func deleteCourse(at offsets: IndexSet){
        courses.remove(atOffsets: offsets)
        save()
    }
    
    // Storage
    private func save() {
        if let data = try? JSONEncoder().encode(courses) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Course].self, from: data) {
            courses = saved
        }
    }
    
}


class CheckIns: ObservableObject{
    @Published var checks: [CheckIn] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("tasks.json")
    
    init() {
       load()
   }
    
    func addCheckin(courseID: String, rating: Int){
        let newCheck = CheckIn(id: UUID().uuidString, courseID: courseID, rating: rating, date: Date())
        checks.append(newCheck)
        save()
        
    }
    
    func deleteCheckIn(at offsets: IndexSet){
        checks.remove(atOffsets: offsets)
        save()
    }
    // Storage
    private func save() {
        if let data = try? JSONEncoder().encode(checks) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([CheckIn].self, from: data) {
            checks = saved
        }
    }
}

class Feedbacks: ObservableObject{
    @Published var Feed: [Feedback] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("tasks.json")
    
    init() {
       load()
   }
    
    func addFeed(courseID: String, category: FeedbackCategory, comment: String, upVote: Int, status: FeedbackStatus){
        let newFeed = Feedback(id: UUID().uuidString, courseID: courseID, category: category, comment: comment, upvoteCount: upVote, status: status, professorReply: nil, createdAt: Date())
        Feed.append(newFeed)
        save()
    }
    
    func deleteFeed(at offsets: IndexSet){
        Feed.remove(atOffsets: offsets)
        save()
    }
    
    // Storage
    private func save() {
        if let data = try? JSONEncoder().encode(Feed) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Feedback].self, from: data) {
            Feed = saved
        }
    }
    
    
}
