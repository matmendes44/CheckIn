import SwiftUI
internal import Combine

struct StudentHomeView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var model: HomeViewModel
    @State private var showJoin = false

    init(service: CourseService, user: User) {
        _model = StateObject(wrappedValue: HomeViewModel(service: service, user: user))
    }

    var body: some View {
        Group {
            if model.courses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical").font(.system(size: 50))
                    Text("No courses yet").font(.title2.bold())
                    Text("Tap + in the top right and enter the code your professor gave you.")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding()
            } else {
                List {
                    Section {
                        ForEach(model.courses) { course in
                            NavigationLink(value: course.id) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.name).font(.headline)
                                    if !course.professorName.isEmpty {
                                        Text(course.professorName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Your Courses").foregroundStyle(.white)
                    } footer: {
                        Text("You're signed in anonymously. Professors and classmates can't see who you are.")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable { await model.load() }
            }
        }
        .navigationTitle("My Courses")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showJoin = true } label: {
                    Image(systemName: "plus").foregroundStyle(.white)
                }
                .accessibilityLabel("Add course code")
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Sign Out") { env.signOut() }.foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showJoin) {
            JoinCourseSheet(model: model)
                .presentationDetents([.medium])
        }
        .task { await model.load() }
        .alert("Something went wrong",
               isPresented: Binding(
                    get: { model.errorMessage != nil && !showJoin },
                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct JoinCourseSheet: View {
    @ObservedObject var model: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Course code") {
                    TextField("e.g. K7P2QX", text: $code)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { Task { await join() } }
                }
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Join Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.errorMessage = nil; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") { Task { await join() } }
                        .disabled(isWorking || code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { model.errorMessage = nil }
        }
    }

    private func join() async {
        isWorking = true
        defer { isWorking = false }
        if await model.join(code: code) { dismiss() }
    }
}
