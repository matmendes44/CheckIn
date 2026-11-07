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
    
    func addUser(name: String, role: UserRole){
        let newUser = User(id: UUID().uuidString, name: name, role: role)
        users.append(newUser)
    }
    
    func deleteUsers(at offsets: IndexSet){
        users.remove(atOffsets: offsets)
    }
    
    
}


class CourseProfessors: ObservableObject{
    
    @Published var courses: [Course] = []
    
    func addCourse(name: String, code: String, professorID: String){
        let newCourse = Course(id: UUID().uuidString, name: name, joinCode: code, professorID: professorID)
        courses.append(newCourse)
    }
    
    func deleteCourse(at offsets: IndexSet){
        courses.remove(atOffsets: offsets)
    }
    
}


class CheckIns: ObservableObject{
    @Published var checks: [CheckIn] = []
    
    func addCheckin(courseID: String, rating: Int){
        let newCheck = CheckIn(id: UUID().uuidString, courseID: courseID, rating: rating, date: Date())
        checks.append(newCheck)
        
    }
    
    func deleteCheckIn(at offsets: IndexSet){
        checks.remove(atOffsets: offsets)
    }
}

class Feedbacks: ObservableObject{
    @Published var Feed: [Feedback] = []
    
    func addFeed(courseID: String, category: FeedbackCategory, comment: String, upVote: Int, status: FeedbackStatus){
        let newFeed = Feedback(id: UUID().uuidString, courseID: courseID, category: category, comment: comment, upvoteCount: upVote, status: status, professorReply: nil, createdAt: Date())
        Feed.append(newFeed)
    }
    
    func deleteFeed(at offsets: IndexSet){
        Feed.remove(atOffsets: offsets)
    }
}
