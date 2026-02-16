import Foundation
import SwiftUI

/// Configuration for the FeedbackFlow package.
public struct FeedbackFlowConfig {
    let supabaseUrl: String
    let supabaseAnonKey: String
    let theme: FeedbackTheme

    public init(
        supabaseUrl: String,
        supabaseAnonKey: String,
        theme: FeedbackTheme = .default
    ) {
        self.supabaseUrl = supabaseUrl
        self.supabaseAnonKey = supabaseAnonKey
        self.theme = theme
    }
}
