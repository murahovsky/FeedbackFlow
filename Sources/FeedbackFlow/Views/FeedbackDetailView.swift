
import SwiftUI

/// Detail view for a single feedback request, with comments.
struct FeedbackDetailView: View {
    let request: FeedbackRequest
    let hasVoted: Bool
    let onToggleVote: () -> Void

    @StateObject private var viewModel = FeedbackDetailViewModel()
    @State private var commentText = ""
    @FocusState private var isCommentFocused: Bool

    private var theme: FeedbackTheme {
        FeedbackFlow.currentConfig?.theme ?? .default
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header card
                    headerCard

                    // Description
                    if let desc = request.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey(L10nKey.FeedbackDetail.description))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.secondaryText)
                                .textCase(.uppercase)
                                .kerning(0.5)

                            Text(desc)
                                .font(.system(size: 15))
                                .foregroundColor(theme.text.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Comments section
                    commentsSection

                    Spacer(minLength: 80)
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            // Comment input bar
            VStack {
                Spacer()
                commentInputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments(requestId: request.id)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Vote
                Button(action: onToggleVote) {
                    VStack(spacing: 4) {
                        Image(systemName: AppImageKey.SF.chevronUp)
                            .font(.system(size: 16, weight: .bold))
                        Text("\(request.voteCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                    }
                    .foregroundColor(hasVoted ? .green : theme.secondaryText)
                    .frame(width: 52, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasVoted ? Color.green.opacity(0.12) : theme.background.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hasVoted ? Color.green.opacity(0.3) : theme.secondaryText.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 8) {
                    Text(request.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.text)

                    StatusBadge(status: request.status, theme: theme)
                }

                Spacer(minLength: 0)
            }

            // Meta
            HStack(spacing: 16) {
                Label(request.createdAt.formatted(.dateTime.month().day().year()), systemImage: AppImageKey.SF.calendar)
                Label(votesLabel, systemImage: AppImageKey.SF.handThumbsup)
            }
            .font(.system(size: 12))
            .foregroundColor(theme.secondaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.secondaryText.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var votesLabel: String {
        if request.voteCount == 1 {
            let format = String(localized: LocalizedStringResource(stringLiteral: L10nKey.FeedbackDetail.votesOne))
            return String(format: format, locale: Locale.current, request.voteCount)
        } else {
            let format = String(localized: LocalizedStringResource(stringLiteral: L10nKey.FeedbackDetail.votesOther))
            return String(format: format, locale: Locale.current, request.voteCount)
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey(L10nKey.FeedbackDetail.comments))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .textCase(.uppercase)
                    .kerning(0.5)

                if !viewModel.comments.isEmpty {
                    Text("\(viewModel.comments.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.secondaryBackground)
                        )
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(theme.accent)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if viewModel.comments.isEmpty {
                Text(LocalizedStringKey(L10nKey.FeedbackDetail.commentsEmpty))
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRow(comment: comment, theme: theme)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField(String(localized: LocalizedStringResource(stringLiteral: L10nKey.FeedbackDetail.addCommentPlaceholder)), text: $commentText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(theme.text)
                .lineLimit(1...4)
                .focused($isCommentFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.secondaryText.opacity(0.1), lineWidth: 1)
                )

            Button {
                Task { await submitComment() }
            } label: {
                Image(systemName: AppImageKey.SF.arrowCircleUp)
                    .font(.system(size: 32))
                    .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? theme.secondaryText.opacity(0.3)
                        : theme.accent
                    )
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(theme.background)
                .shadow(color: .black.opacity(0.15), radius: 8, y: -4)
        )
    }

    private func submitComment() async {
        let body = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        commentText = ""
        isCommentFocused = false
        await viewModel.submitComment(requestId: request.id, body: body)
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    let comment: FeedbackComment
    let theme: FeedbackTheme

    private var isMyComment: Bool {
        guard let service = FeedbackFlow.service else { return false }
        return comment.deviceId == service.deviceId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isMyComment
                    ? LocalizedStringKey(L10nKey.FeedbackDetail.authorYou)
                    : LocalizedStringKey(L10nKey.FeedbackDetail.authorUser)
                )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isMyComment ? theme.accent : theme.secondaryText)

                Spacer()

                Text(comment.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
            }

            Text(comment.body)
                .font(.system(size: 14))
                .foregroundColor(theme.text.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.secondaryText.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - ViewModel

@MainActor
final class FeedbackDetailViewModel: ObservableObject {
    @Published var comments: [FeedbackComment] = []
    @Published var isLoading = false
    @Published var isSending = false

    func loadComments(requestId: UUID) async {
        guard let service = FeedbackFlow.service else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            comments = try await service.fetchComments(requestId: requestId)
        } catch {
            #if DEBUG
            print("FeedbackFlow: Failed to load comments: \(error)")
            #endif
        }
    }

    func submitComment(requestId: UUID, body: String) async {
        guard let service = FeedbackFlow.service else { return }
        isSending = true
        defer { isSending = false }

        do {
            try await service.submitComment(requestId: requestId, body: body)
            await loadComments(requestId: requestId)
        } catch {
            #if DEBUG
            print("FeedbackFlow: Failed to submit comment: \(error)")
            #endif
        }
    }
}
