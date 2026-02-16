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

    /// The feedback list view. Use as: `FeedbackFlow.FeedbackListView()`
    public struct FeedbackListView: View {
        public init() {}

        public var body: some View {
            FeedbackListViewContent()
        }
    }
}
