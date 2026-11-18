import SwiftUI
import Charts
internal import Combine



private func label(_ value: Any) -> String {
    String(describing: value).capitalized
}

// CourseDetail View Model

@MainActor
final class CourseDetailViewModel: ObservableObject {
    @Published var feedback: [Feedback] = []
    @Published var trend: [RatingTrendPoint] = []
    @Published var errorMessage: String?
    @Published var checkedIn = false

    let courseID: String
    let user: User
    private let feedbackService: FeedbackService
    private let checkInService: CheckInService

    init(courseID: String, user: User, feedback: FeedbackService, checkIns: CheckInService) {
        self.courseID = courseID
        self.user = user
        self.feedbackService = feedback
        self.checkInService = checkIns
    }

    func load() async {
        do {
            feedback = try await feedbackService.feedback(for: courseID)   // sorted by upvotes
            trend = try await checkInService.trend(for: courseID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func submitFeedback(category: FeedbackCategory, comment: String) async -> Bool {
        errorMessage = nil
        do {
            try await feedbackService.submit(courseID: courseID, category: category, comment: comment)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription   // includes moderation rejections
            return false
        }
    }

    func toggleUpvote(_ id: String) async {
        do { try await feedbackService.toggleUpvote(feedbackID: id); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    @discardableResult
    func reply(to id: String, text: String) async -> Bool {
        errorMessage = nil
        do { try await feedbackService.reply(feedbackID: id, text: text); await load(); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }

    func setStatus(_ id: String, _ status: FeedbackStatus) async {
        do { try await feedbackService.setStatus(feedbackID: id, status: status); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    func checkIn(rating: Int) async {
        let checkIn = CheckIn(id: UUID().uuidString, courseID: courseID, rating: rating, date: Date())
        do {
            try await checkInService.submit(courseID: courseID, checkIn: checkIn)
            checkedIn = true
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
}

//  Page Load

struct CourseDetailView: View {
    @StateObject private var model: CourseDetailViewModel
    let courseName: String
    let professorName: String

    @State private var showSubmit = false
    @State private var replyTarget: Feedback?

    init(courseID: String, courseName: String, professorName: String,
         user: User, feedback: FeedbackService, checkIns: CheckInService) {
        self.courseName = courseName
        self.professorName = professorName
        _model = StateObject(wrappedValue: CourseDetailViewModel(
            courseID: courseID, user: user, feedback: feedback, checkIns: checkIns))
    }

    private var isProfessor: Bool { model.user.role == .professor }

    var body: some View {
        ZStack {
            AppBackground()
            List {
                if !isProfessor {
                    Section { CheckInCard(model: model) }
                }

                if !model.trend.isEmpty {
                    Section("Class rating over time") {
                        Chart {
                            ForEach(model.trend, id: \.date) { point in
                                LineMark(x: .value("Day", point.date, unit: .day),
                                         y: .value("Average", point.average))
                                PointMark(x: .value("Day", point.date, unit: .day),
                                          y: .value("Average", point.average))
                            }
                        }
                        .chartYScale(domain: 1...5)
                        .frame(height: 160)
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    if model.feedback.isEmpty {
                        Text(isProfessor ? "No comments yet."
                                         : "No comments yet. Be the first to share something, anonymously.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.feedback, id: \.id) { item in
                        FeedbackRow(
                            feedback: item,
                            isProfessor: isProfessor,
                            professorName: professorName,
                            onUpvote: { Task { await model.toggleUpvote(item.id) } },
                            onReply: { replyTarget = item },
                            onStatus: { status in Task { await model.setStatus(item.id, status) } })
                    }
                } header: {
                    Text("Comments").foregroundStyle(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .refreshable { await model.load() }
        }
        .navigationTitle(courseName)
        .toolbar {
            if !isProfessor {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSubmit = true } label: {
                        Image(systemName: "square.and.pencil").foregroundStyle(.white)
                    }
                    .accessibilityLabel("Write a comment")
                }
            }
        }
        .sheet(isPresented: $showSubmit) {
            SubmitFeedbackSheet(model: model)
        }
        .sheet(isPresented: Binding(get: { replyTarget != nil },
                                    set: { if !$0 { replyTarget = nil } })) {
            if let target = replyTarget {
                ReplySheet(model: model, feedback: target)
            }
        }
        .task { await model.load() }
        .alert("Something went wrong",
               isPresented: Binding(
                    get: { model.errorMessage != nil && !showSubmit && replyTarget == nil },
                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}

// Submissions

struct FeedbackRow: View {
    let feedback: Feedback
    let isProfessor: Bool
    let professorName: String
    var onUpvote: () -> Void
    var onReply: () -> Void
    var onStatus: (FeedbackStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label(feedback.category))
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                Spacer()
                if isProfessor {
                    Menu {
                        ForEach(Array(FeedbackStatus.allCases), id: \.self) { status in
                            Button(label(status)) { onStatus(status) }
                        }
                    } label: {
                        Label(label(feedback.status), systemImage: "chevron.down")
                            .font(.caption)
                    }
                } else {
                    Text(label(feedback.status)).font(.caption).foregroundStyle(.secondary)
                }
            }

            Text(feedback.comment)

            HStack {
                Text("Anonymous student • " + feedback.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(action: onUpvote) {
                    Label("\(feedback.upvoteCount)", systemImage: "arrow.up.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Upvote, \(feedback.upvoteCount) so far")
            }

            if let reply = feedback.professorReply, !reply.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(professorName.isEmpty ? "Professor" : professorName)
                        .font(.caption.bold())
                    Text(reply).font(.subheadline)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.1)))
            }

            if isProfessor {
                Button(feedback.professorReply == nil ? "Reply" : "Edit reply", action: onReply)
                    .buttonStyle(.borderless)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CheckInCard: View {
    @ObservedObject var model: CourseDetailViewModel
    @State private var rating = 0

    var body: some View {
        VStack(spacing: 10) {
            if model.checkedIn {
                Label("Thanks for checking in!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("How was class today?").font(.headline)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(.orange)
                            .onTapGesture { rating = star }
                            .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    }
                }
                Button("Submit rating") { Task { await model.checkIn(rating: rating) } }
                    .buttonStyle(.borderedProminent)
                    .disabled(rating == 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

struct SubmitFeedbackSheet: View {
    @ObservedObject var model: CourseDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var category: FeedbackCategory = FeedbackCategory.allCases.first!
    @State private var comment = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(Array(FeedbackCategory.allCases), id: \.self) { Text(label($0)).tag($0) }
                    }
                }
                Section("Your feedback") {
                    TextEditor(text: $comment).frame(minHeight: 120)
                }
                Section {
                    if let error = model.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                } footer: {
                    Text("Your feedback is anonymous. Your professor and classmates can't see who wrote it.")
                }
            }
            .navigationTitle("New Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.errorMessage = nil; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            isWorking = true
                            if await model.submitFeedback(category: category, comment: comment) { dismiss() }
                            isWorking = false
                        }
                    }
                    .disabled(isWorking || comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { model.errorMessage = nil }
        }
    }
}

struct ReplySheet: View {
    @ObservedObject var model: CourseDetailViewModel
    let feedback: Feedback
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(model: CourseDetailViewModel, feedback: Feedback) {
        self.model = model
        self.feedback = feedback
        _text = State(initialValue: feedback.professorReply ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") { Text(feedback.comment) }
                Section("Your reply") { TextEditor(text: $text).frame(minHeight: 100) }
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Reply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.errorMessage = nil; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task { if await model.reply(to: feedback.id, text: text) { dismiss() } }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { model.errorMessage = nil }
        }
    }
}
