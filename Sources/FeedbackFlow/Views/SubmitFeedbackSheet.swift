import SwiftUI

/// Sheet for submitting a new feature request.
struct SubmitFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    var onSubmitted: (() -> Void)?

    private var theme: FeedbackTheme {
        FeedbackFlow.currentConfig?.theme ?? .default
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                if didSubmit {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.green)

                        Text("Thank you!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(theme.text)

                        Text("Your request has been submitted.\nWe'll review it shortly.")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Title field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.secondaryText)

                                ThemedTextField(
                                    placeholder: "What would you like to see?",
                                    text: $title,
                                    theme: theme
                                )
                            }

                            // Description field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.secondaryText)

                                TextEditor(text: $description)
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.text)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.secondaryBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.secondaryText.opacity(0.1), lineWidth: 1)
                                    )
                            }

                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.secondaryText)

                                ThemedTextField(
                                    placeholder: "your@email.com",
                                    text: $email,
                                    theme: theme,
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    autocapitalization: false
                                )

                                Text("Leave your email if you'd like us to follow up")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.secondaryText.opacity(0.7))
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !didSubmit {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(theme.accent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if didSubmit {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                    } else {
                        Button {
                            Task { await submit() }
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(theme.accent)
                            } else {
                                Text("Submit")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(canSubmit ? theme.accent : theme.secondaryText)
                        .disabled(!canSubmit)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func submit() async {
        guard let service = FeedbackFlow.service else { return }
        isSubmitting = true
        errorMessage = nil

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await service.submitRequest(
                title: trimmedTitle,
                description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail
            )
            FeedbackFlow.onFeedbackSubmitted?(!trimmedEmail.isEmpty)
            onSubmitted?()
            withAnimation { didSubmit = true }
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

// MARK: - Themed TextField (placeholder uses theme colors)

private struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    let theme: FeedbackTheme
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: Bool = true

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                    .padding(.horizontal, 14)
            }
            TextField("", text: $text)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(autocapitalization ? .sentences : .never)
                .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
}
