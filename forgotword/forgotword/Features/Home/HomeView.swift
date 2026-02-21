import SwiftUI
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var dueItems: [StudyItem] = []
    @Published private(set) var upcomingItems: [StudyItem] = []
    @Published private(set) var reviewingItemIDs: Set<UUID> = []
    @Published var errorMessage: String?

    private var observeTask: Task<Void, Never>?
    private var itemRepository: (any ItemRepository)?
    private var reviewService: ReviewService?

    func start(using environment: AppEnvironment) async {
        guard observeTask == nil else { return }
        itemRepository = environment.itemRepository
        reviewService = environment.reviewService

        let repository = environment.itemRepository
        observeTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in repository.observeItems(includeArchived: false) {
                let now = Date()
                let due = snapshot
                    .filter { !$0.isArchived && $0.nextDueAt <= now }
                    .sorted { lhs, rhs in
                        if lhs.nextDueAt == rhs.nextDueAt {
                            return lhs.createdAt < rhs.createdAt
                        }
                        return lhs.nextDueAt < rhs.nextDueAt
                    }
                let upcoming = snapshot
                    .filter { !$0.isArchived && $0.nextDueAt > now }
                    .sorted { lhs, rhs in
                        if lhs.nextDueAt == rhs.nextDueAt {
                            return lhs.createdAt < rhs.createdAt
                        }
                        return lhs.nextDueAt < rhs.nextDueAt
                    }
                await MainActor.run {
                    self.dueItems = due
                    self.upcomingItems = Array(upcoming.prefix(10))
                }
            }
        }
    }

    func review(item: StudyItem, feedback: StudyItem.ReviewHistoryEntry.Result) {
        guard let service = reviewService else { return }
        let itemID = item.id
        reviewingItemIDs.insert(itemID)

        Task {
            do {
                try await service.record(itemID: itemID, feedback: feedback)
            } catch {
                await MainActor.run {
                    self.errorMessage = "復習の更新に失敗しました"
                }
            }

            await MainActor.run {
                self.reviewingItemIDs.remove(itemID)
            }
        }
    }

    deinit {
        observeTask?.cancel()
    }
}


struct HomeView: View {
    @Environment(\.appEnvironment) private var environment
    @StateObject private var viewModel = HomeViewModel()
    @State private var authorizationStatus: NotificationAuthorizationStatus = .notDetermined
    @State private var isPresentingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { isPresentingAdd = true } label: {
                        Label("アイテムを追加", systemImage: "plus")
                    }
                }
                if let focusItem = viewModel.dueItems.first ?? viewModel.upcomingItems.first {
                    Section("忘却度") {
#if canImport(Charts)
                        if #available(iOS 16.0, *) {
                            ForgettingCurveCard(item: focusItem, now: Date())
                        } else {
                            Text("忘却度グラフはiOS 16以降で利用できます。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
#else
                        Text("忘却度グラフは現在の環境では利用できません。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
#endif
                    }
                }
                if authorizationStatus != .authorized {
                    Section("通知") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("通知がオフになっています。復習のリマインドを受け取るには、通知を許可してください。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button(action: requestPermission) {
                                Text("通知を許可する")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("今日の復習") {
                    if viewModel.dueItems.isEmpty {
                        Label("今のところ復習はありません", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.dueItems) { item in
                            DueItemRow(
                                item: item,
                                isProcessing: viewModel.reviewingItemIDs.contains(item.id),
                                action: { feedback in
                                    viewModel.review(item: item, feedback: feedback)
                                }
                            )
                        }
                    }
                }

                if !viewModel.upcomingItems.isEmpty {
                    Section("次回の予定") {
                        ForEach(viewModel.upcomingItems) { item in
                            UpcomingItemRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("忘却メモ")
            .task { await refreshAuthorizationStatus() }
            .task { await viewModel.start(using: environment) }
            .alert(
                "エラー",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("閉じる", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isPresentingAdd = true }) {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddItemView()
                .environment(\.appEnvironment, environment)
        }
    }

    private func refreshAuthorizationStatus() async {
        let status = await environment.notificationScheduler.authorizationStatus()
        await MainActor.run {
            authorizationStatus = status
        }
    }

    private func requestPermission() {
        Task {
            let granted = (try? await environment.notificationScheduler.requestAuthorization()) ?? false
            let status = await environment.notificationScheduler.authorizationStatus()
            await MainActor.run {
                authorizationStatus = granted ? .authorized : status
            }
        }
    }
}

private struct DueItemRow: View {
    let item: StudyItem
    let isProcessing: Bool
    let action: (StudyItem.ReviewHistoryEntry.Result) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.deck)
                    .font(.headline)
                Text(item.rangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let page = item.page, !page.isEmpty {
                    Text(page)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                FeedbackButton(
                    label: "Bad",
                    systemImage: "arrow.uturn.backward",
                    tint: .red,
                    isProcessing: isProcessing,
                    action: { action(.bad) }
                )
                FeedbackButton(
                    label: "Good",
                    systemImage: "checkmark.circle",
                    tint: .blue,
                    isProcessing: isProcessing,
                    action: { action(.good) }
                )
                FeedbackButton(
                    label: "Great",
                    systemImage: "sun.max",
                    tint: .green,
                    isProcessing: isProcessing,
                    action: { action(.great) }
                )

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

private struct FeedbackButton: View {
    let label: String
    let systemImage: String
    let tint: Color
    let isProcessing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
        .disabled(isProcessing)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environment(\.appEnvironment, .preview())
}

struct AddItemView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var deck: String = ""
    @State private var range: String = ""
    @State private var page: String = ""
    @State private var profile: MemoryProfile = .standard
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("単語帳名", text: $deck)
                    TextField("範囲", text: $range)
                    TextField("ページ (任意)", text: $page)
                }

                Section(header: Text("プロファイル")) {
                    Picker("忘れやすさ", selection: $profile) {
                        ForEach(MemoryProfile.allCases) { profile in
                            Text(profile.title).tag(profile)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("アイテムを追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(isSaving)
                }
            }
            .disabled(isSaving)
            .alert("エラー", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("閉じる", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        if isSaving { return }
        let trimmedDeck = deck.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRange = range.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDeck.isEmpty else {
            errorMessage = "単語帳名を入力してください"
            return
        }
        guard !trimmedRange.isEmpty else {
            errorMessage = "範囲を入力してください"
            return
        }
        isSaving = true
        let trimmedPage = page.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await environment.itemCreationService.createItem(
                    deck: trimmedDeck,
                    rangeText: trimmedRange,
                    page: trimmedPage.isEmpty ? nil : trimmedPage,
                    profile: profile
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch let error as ItemCreationService.Error {
                let message: String
                switch error {
                case .deckRequired: message = "単語帳名を入力してください"
                case .rangeRequired: message = "範囲を入力してください"
                case .limitReached: message = "無料プランの上限（10件）に達しました"
                }
                await MainActor.run {
                    isSaving = false
                    errorMessage = message
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "作成に失敗しました"
                }
            }
        }
    }
}

private struct UpcomingItemRow: View {
    let item: StudyItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.deck)
                .font(.headline)
            Text(item.rangeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Self.formatter.string(from: item.nextDueAt))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
