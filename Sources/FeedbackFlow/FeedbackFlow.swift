import SwiftUI

/// Main entry point for the FeedbackFlow package.
///
/// Usage:
/// ```swift
/// // 1. Configure at app launch
/// FeedbackFlow.configure(
///     supabaseUrl: "https://xxx.supabase.co",
///     supabaseAnonKey: "eyJ...",
///     theme: .init(accent: .blue, ...)
/// )
///
/// // 2. Present in SwiftUI
/// FeedbackFlow.FeedbackListView()
/// ```
public enum FeedbackFlow {
    internal static var currentConfig: FeedbackFlowConfig?
    internal static var service: FeedbackService?

    /// Callback when a feedback request is submitted. Parameter: hasEmail.
    public static var onFeedbackSubmitted: ((Bool) -> Void)?

    /// Callback when the user saves their email on the board.
    public static var onEmailCaptured: (() -> Void)?

    /// Callback when a vote is toggled. Parameter: "vote" or "unvote".
    public static var onVoteToggled: ((String) -> Void)?

    /// Configure FeedbackFlow with Supabase credentials and an optional theme.
    public static func configure(
        supabaseUrl: String,
        supabaseAnonKey: String,
        theme: FeedbackTheme = .default
    ) {
        let config = FeedbackFlowConfig(
            supabaseUrl: supabaseUrl,
            supabaseAnonKey: supabaseAnonKey,
            theme: theme
        )
        currentConfig = config
        service = FeedbackService(baseUrl: supabaseUrl, anonKey: supabaseAnonKey)

        #if DEBUG
        print("✅ FeedbackFlow configured (\(supabaseUrl))")
        #endif
    }

    /// Sends an open survey answer ("what do you like / what could be better").
    /// Answers go to their own table and never appear on the request board.
    /// A non-empty email is also saved for this device, like on the board.
    public static func submitSurvey(
        rating: Int?,
        liked: String?,
        improve: String,
        email: String?,
        appVersion: String?,
        posthogId: String?
    ) async throws {
        guard let service else { throw FeedbackError.notConfigured }
        func clean(_ text: String?) -> String? {
            let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        guard let improve = clean(improve) else { return }
        let email = clean(email)
        try await service.submitSurvey(CreateSurveyPayload(
            deviceId: service.deviceId,
            rating: rating.map { min(max($0, 1), 5) },
            liked: clean(liked),
            improve: improve,
            email: email,
            appVersion: appVersion,
            posthogId: posthogId
        ))
        if let email {
            try? await service.saveDeviceEmail(email)
        }
    }

    /// The email this device has already given FeedbackFlow, if any.
    public static var storedEmail: String? { service?.storedEmail }

    /// The feedback list view. Use as: `FeedbackFlow.FeedbackListView()`
    public struct FeedbackListView: View {
        public init() {}

        public var body: some View {
            FeedbackListViewContent()
        }
    }
}
