import SwiftUI

/// Asked once per device, right after the first vote.
///
/// The vote is already counted by the time this appears, so dismissing it
/// costs the user nothing and costs us no signal. Voting stays a single tap.
struct EmailCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var theme: FeedbackTheme {
        FeedbackFlow.currentConfig?.theme ?? .default
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        guard !isSaving, let at = trimmedEmail.firstIndex(of: "@"), at != trimmedEmail.startIndex else {
            return false
        }
        let domain = trimmedEmail[trimmedEmail.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thanks for voting")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(theme.text)

                        Text("Leave your email and we'll let you know when this ships. That's all we use it for.")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ThemedTextField(
                        placeholder: "your@email.com",
                        text: $email,
                        theme: theme,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: false
                    )

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Not now") {
                        dismiss()
                    }
                    .foregroundColor(theme.secondaryText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(theme.accent)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(canSave ? theme.accent : theme.secondaryText)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    private func save() async {
        guard let service = FeedbackFlow.service else { return }
        isSaving = true
        errorMessage = nil

        do {
            try await service.saveDeviceEmail(trimmedEmail)
            FeedbackFlow.onEmailCaptured?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
