//
//  ContentView.swift
//  CheckIn
//
// View for thread display and interaction in the CheckIn app.
// View section created by Aniyah Davis

import SwiftUI
import Foundation




struct ContentView: View {
    var body: some View {
        
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("CheckIn")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("CheckIn")
        }
        .padding()
    }
    
    struct LoginPage: View {
        var body: some View {
            Text("Login Screen")
        }
    }
}


struct AuthenticationScreen: View {
    var body: some View {
        Text("Authentication Screen")
    }

}

/*  TEMP Disabled
 
 struct CourseThread: View {
    @Environment(EntitiesModel.self) var entitiesModel

    let thread: Thread
    let onUpvote: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Button(action: onUpvote) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.borderless)

                Text("\(thread.score)")
                    .font(.caption.monospacedDigit())
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text("r/\(thread.subreddit) · u/\(thread.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(thread.title)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(thread.commentCount)", systemImage: "bubble.right")
                    Text(thread.createdAt, format: .relative(presentation: .named))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CourseThreadDetailView: View {
    @Environment(EntitiesModel.self) var entitiesModel
    @Environment(\.dismiss) var dismiss

    let thread: Thread

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(thread.title).font(.title2.bold())
                Text(thread.body)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("r/\(thread.subreddit)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        }
    }
}
*/

struct CourseThreadPostCreation: View {
    //  Temp Disabled
    //@Environment(EntitiesModel.self) var entitiesModel

   @State private var title: String = ""
   @State private var postbody: String = ""
   @State private var user: String = ""
   @State private var subthread: String = ""

    var body: some View {
        Text("Course Thread Post Creation Screen")
         }

    }

#Preview {
    ContentView()
}
