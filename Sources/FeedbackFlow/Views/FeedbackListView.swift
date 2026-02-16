import SwiftUI

/// Internal view showing approved feature requests with voting.
/// Exposed publicly via `FeedbackFlow.FeedbackListView`.
struct FeedbackListViewContent: View {
    @StateObject private var viewModel = FeedbackListViewModel()
    @State private var showSubmitSheet = false
    @State private var selectedFilter: StatusFilter = .all

    private var theme: FeedbackTheme {
        FeedbackFlow.currentConfig?.theme ?? .default
    }

    private var filteredRequests: [FeedbackRequest] {
        switch selectedFilter {
        case .all:
            return viewModel.requests
        case .status(let status):
            return viewModel.requests.filter { $0.status == status }
        }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView()
                    .tint(theme.accent)
            } else if viewModel.requests.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    statusFilterBar

                    if filteredRequests.isEmpty {
                        Spacer()
                        Text("No requests with this status")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                    } else {
                        requestList
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(isPresented: $showSubmitSheet) {
            SubmitFeedbackSheet(onSubmitted: {
                Task { await viewModel.loadData() }
            })
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Status Filter Bar

    private var statusFilterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All",
                        count: viewModel.requests.count,
                        isSelected: selectedFilter == .all,
                        color: theme.accent,
                        theme: theme
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = .all }
                    }

                    ForEach(visibleStatuses, id: \.self) { status in
                        let count = viewModel.requests.filter { $0.status == status }.count
                        if count > 0 {
                            FilterChip(
                                label: status.displayLabel,
                                count: count,
                                isSelected: selectedFilter == .status(status),
                                color: status.badgeColor,
                                theme: theme
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = .status(status) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()
                .background(theme.secondaryText.opacity(0.15))
        }
    }

    private var visibleStatuses: [FeedbackRequest.Status] {
        [.planned, .inProgress, .inReview, .completed]
    }

    // MARK: - Request List

    private var requestList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRequests) { request in
                    NavigationLink {
                        FeedbackDetailView(
                            request: request,
                            hasVoted: viewModel.votedIds.contains(request.id),
                            onToggleVote: {
                                Task { await viewModel.toggleVote(for: request) }
                            }
                        )
                    } label: {
                        FeedbackRow(
                            request: request,
                            hasVoted: viewModel.votedIds.contains(request.id),
                            theme: theme,
                            onToggleVote: {
                                Task { await viewModel.toggleVote(for: request) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.loadData()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(theme.secondaryText.opacity(0.4))

            Text("No feature requests yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.text)

            Text("Be the first to suggest an improvement!")
                .font(.system(size: 15))
                .foregroundColor(theme.secondaryText)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showSubmitSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.background)
                .frame(width: 56, height: 56)
                .background(theme.accent)
                .clipShape(Circle())
                .shadow(color: theme.accent.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Status Filter

enum StatusFilter: Equatable {
    case all
    case status(FeedbackRequest.Status)
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let theme: FeedbackTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(isSelected ? color : theme.secondaryText.opacity(0.6))
            }
            .foregroundColor(isSelected ? color : theme.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.12) : theme.secondaryBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row

private struct FeedbackRow: View {
    let request: FeedbackRequest
    let hasVoted: Bool
    let theme: FeedbackTheme
    let onToggleVote: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VoteButton(
                count: request.voteCount,
                hasVoted: hasVoted,
                theme: theme,
                action: onToggleVote
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(request.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.text)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    StatusDot(status: request.status)
                }

                if let desc = request.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(2)
                }

                StatusBadge(status: request.status, theme: theme)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.secondaryText.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Vote Button

private struct VoteButton: View {
    let count: Int
    let hasVoted: Bool
    let theme: FeedbackTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .bold))
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundColor(hasVoted ? .green : theme.secondaryText)
            .frame(width: 44, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hasVoted ? Color.green.opacity(0.12) : theme.background.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(hasVoted ? Color.green.opacity(0.3) : theme.secondaryText.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Dot (subtle indicator in row header)

private struct StatusDot: View {
    let status: FeedbackRequest.Status

    var body: some View {
        Circle()
            .fill(status.badgeColor)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: FeedbackRequest.Status
    let theme: FeedbackTheme

    var body: some View {
        Text(status.displayLabel)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(status.badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(status.badgeColor.opacity(0.12))
            )
    }
}

// MARK: - Status Helpers

extension FeedbackRequest.Status {
    var displayLabel: String {
        switch self {
        case .pending: return "Pending"
        case .inReview: return "In Review"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var badgeColor: Color {
        switch self {
        case .pending: return .gray
        case .inReview: return .blue
        case .planned: return .purple
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
}

// MARK: - ViewModel

@MainActor
final class FeedbackListViewModel: ObservableObject {
    @Published var requests: [FeedbackRequest] = []
    @Published var votedIds: Set<UUID> = []
    @Published var isLoading = false

    func loadData() async {
        guard let service = FeedbackFlow.service else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedRequests = service.fetchRequests()
            async let fetchedVotes = service.fetchMyVotes()
            let (reqs, votes) = try await (fetchedRequests, fetchedVotes)
            requests = reqs
            votedIds = votes
        } catch {
            #if DEBUG
            print("FeedbackFlow: Failed to load data: \(error)")
            #endif
        }
    }

    func toggleVote(for request: FeedbackRequest) async {
        guard let service = FeedbackFlow.service else { return }

        let wasVoted = votedIds.contains(request.id)
        if wasVoted {
            votedIds.remove(request.id)
        } else {
            votedIds.insert(request.id)
        }
        if let idx = requests.firstIndex(where: { $0.id == request.id }) {
            let delta = wasVoted ? -1 : 1
            let old = requests[idx]
            let updated = FeedbackRequest(
                id: old.id,
                title: old.title,
                description: old.description,
                email: old.email,
                status: old.status,
                voteCount: max(0, old.voteCount + delta),
                deviceId: old.deviceId,
                createdAt: old.createdAt
            )
            requests[idx] = updated
        }

        FeedbackFlow.onVoteToggled?(wasVoted ? "unvote" : "vote")

        do {
            try await service.toggleVote(requestId: request.id)
        } catch {
            if wasVoted {
                votedIds.insert(request.id)
            } else {
                votedIds.remove(request.id)
            }
            await loadData()
            #if DEBUG
            print("FeedbackFlow: Vote toggle failed: \(error)")
            #endif
        }
    }
}
