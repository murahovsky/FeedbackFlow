import SwiftUI

/// Customizable color theme for FeedbackFlow views.
public struct FeedbackTheme: Sendable {
    public var accent: Color
    public var background: Color
    public var secondaryBackground: Color
    public var text: Color
    public var secondaryText: Color

    public init(
        accent: Color,
        background: Color,
        secondaryBackground: Color,
        text: Color,
        secondaryText: Color
    ) {
        self.accent = accent
        self.background = background
        self.secondaryBackground = secondaryBackground
        self.text = text
        self.secondaryText = secondaryText
    }

    /// Default dark theme.
    public static let `default` = FeedbackTheme(
        accent: Color(red: 0.85, green: 0.65, blue: 0.40),
        background: Color(red: 0.10, green: 0.06, blue: 0.04),
        secondaryBackground: Color(red: 0.15, green: 0.10, blue: 0.07),
        text: Color.white,
        secondaryText: Color.white.opacity(0.6)
    )
}
