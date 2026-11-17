import SwiftUI
import AuthenticationServices
internal import Combine

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// Login (one university SSO button for everyone)

struct LoginPage: View {
    @EnvironmentObject var env: AppEnvironment
    @Environment(\.webAuthenticationSession) private var webAuth
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25).fill(.white)
                .frame(width: 350, height: 550)

            VStack(spacing: 20) {
                Text("Welcome!").font(.title).foregroundStyle(Color.accent)
                Text("Sign in with your university account.\nProfessors and students use the same button.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    Task { await signIn() }
                } label: {
                    Label("Sign in with University SSO", systemImage: "building.columns")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)

                #if DEBUG
                Divider()
                Text("Debug only").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Mock professor") { Task { await signIn(mock: true) } }
                    Button("Mock student") { Task { await signIn(mock: false) } }
                }
                .buttonStyle(.bordered)
                #endif

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Text("Students stay anonymous in CheckIn. Your name and email are never stored or shown.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .frame(width: 350, height: 550)
        }
        .padding(.top, 20)
    }

    private func signIn(mock: Bool? = nil) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let authenticate: WebAuthenticate = { url, scheme in
                try await webAuth.authenticate(using: url, callbackURLScheme: scheme)
            }
            if let mock {
                try await env.signIn(using: MockAuthService(asProfessor: mock), authenticate: authenticate)
            } else {
                try await env.signIn(using: env.auth, authenticate: authenticate)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Professor home

@MainActor
final class ProfessorHomeViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var errorMessage: String?

    private let service: CourseService
    let user: User

    init(service: CourseService, user: User) {
        self.service = service
        self.user = user
    }

    func load() async {
        do { courses = try await service.courses(for: user) }
        catch { errorMessage = error.localizedDescription }
    }

    func create(name: String) async -> Course? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Enter a course name."; return nil }
        do {
            let course = try await service.createCourse(name: trimmed)
            await load()
            return course
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

struct ProfessorHomeView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var model: ProfessorHomeViewModel
    @State private var showCreate = false

    init(service: CourseService, user: User) {
        _model = StateObject(wrappedValue: ProfessorHomeViewModel(service: service, user: user))
    }

    var body: some View {
        Group {
            if model.courses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.rectangle.on.folder").font(.system(size: 50))
                    Text("No courses yet").font(.title2.bold())
                    Text("Tap + to create a course and get a join code for your students.")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding()
            } else {
                List {
                    Section {
                        ForEach(model.courses) { course in
                            CourseCodeRow(course: course)
                        }
                    } header: {
                        Text("Courses you teach").foregroundStyle(.white)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(model.user.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus").foregroundStyle(.white)
                }
                .accessibilityLabel("Create course")
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Sign Out") { env.signOut() }.foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateCourseSheet(model: model)
                .presentationDetents([.medium])
        }
        .task { await model.load() }
        .alert("Something went wrong",
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct CourseCodeRow: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name).font(.headline)
            HStack {
                Text(course.joinCode)
                    .font(.system(.title3, design: .monospaced).bold())
                    .textSelection(.enabled)
                Spacer()
                CopyButton(text: course.joinCode)
                ShareLink(item: "Join \"\(course.name)\" on CheckIn with code \(course.joinCode)") {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            #if os(iOS)
            UIPasteboard.general.string = text
            #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            #endif
            copied = true
            Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Copy code")
    }
}

struct CreateCourseSheet: View {
    @ObservedObject var model: ProfessorHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var created: Course?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                if let created {
                    Section("Share this code with your students") {
                        Text(created.joinCode)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .textSelection(.enabled)
                        HStack {
                            CopyButton(text: created.joinCode)
                            Spacer()
                            ShareLink(item: "Join \"\(created.name)\" on CheckIn with code \(created.joinCode)")
                        }
                    }
                } else {
                    Section("Course name") {
                        TextField("e.g. Intro to Computer Science", text: $name)
                            .onSubmit { Task { await create() } }
                    }
                    Section {
                        Button {
                            Task { await create() }
                        } label: {
                            if isWorking { ProgressView() } else { Text("Create course & generate code") }
                        }
                        .disabled(isWorking)
                    } footer: {
                        Text("A unique join code is generated automatically.")
                    }
                }
            }
            .navigationTitle(created == nil ? "New Course" : "Course Created")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(created == nil ? "Cancel" : "Done") { dismiss() }
                }
            }
        }
    }

    private func create() async {
        isWorking = true
        defer { isWorking = false }
        created = await model.create(name: name)
    }
}
