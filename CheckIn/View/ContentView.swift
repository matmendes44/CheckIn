//
//  ContentView.swift
//  CheckIn
//
// View for thread display and interaction in the CheckIn app.
// View section created by Aniyah Davis


import SwiftUI
import Foundation
import AuthenticationServices

struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [.accentColor, .grad],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackground()

                switch env.currentUser?.role {
                case .none:
                    ScrollView { LoginPage() }

                case .some(.professor):
                    ProfessorHomeView(service: env.courses, user: env.currentUser!)
                        .id(env.currentUser!.id)

                default:
                    StudentHomeView(service: env.courses, user: env.currentUser!)
                        .id(env.currentUser!.id)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button("CheckIn") { path = NavigationPath() }
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
        
            .navigationDestination(for: Course.ID.self) { courseID in
                // needed: feedback list / check-in for this course
                Text("Course \(courseID)")
            }
        }
    
        .onChange(of: env.currentUser?.id) { _, _ in
            path = NavigationPath()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment())
}
