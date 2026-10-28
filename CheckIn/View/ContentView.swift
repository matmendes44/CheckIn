//
//  ContentView.swift
//  CheckIn
//
//  Created by Matheus Mendes on 10/23/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {

        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("CheckIn")
            }
            .padding()
            .navigationTitle("CheckIn")
        }
        .padding()
    }
struct CourseThread: View {
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
struct ThreadDetailView: View {
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
        #if os(iOS){
        .navigationBarTitleDisplayMode(.inline)
        }
    }
}
}

#Preview {
    ContentView()
}
