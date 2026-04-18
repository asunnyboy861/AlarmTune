import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSubject: String = AppConstants.Feedback.defaultSubject
    @State private var customSubject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitting: Bool = false
    @State private var submitResult: SubmitResult?

    private let subjects = AppConstants.Feedback.subjects

    private enum SubmitResult: Equatable {
        case success
        case failure(String)
    }

    var body: some View {
        NavigationView {
            Form {
                subjectSection
                nameSection
                emailSection
                messageSection
                submitSection
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Thank You!", isPresented: Binding(
                get: { submitResult != nil },
                set: { if !$0 { submitResult = nil } }
            )) {
                Button("OK") {
                    if submitResult == .success {
                        dismiss()
                    }
                    submitResult = nil
                }
            } message: {
                if case .failure(let error) = submitResult {
                    Text("Failed to submit: \(error)")
                } else {
                    Text("Your feedback has been submitted successfully. We appreciate your input!")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var subjectSection: some View {
        Section {
            VStack(alignment: .leading, spacing: subjectSpacing) {
                ForEach(subjects, id: \.self) { subject in
                    Button {
                        selectedSubject = subject
                        HapticService.shared.selection()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: subjectIcon(subject))
                                .font(.system(size: iconSize))
                                .frame(width: iconFrameWidth)
                                .foregroundColor(selectedSubject == subject ? .accentColor : .secondary)

                            Text(subject)
                                .font(.system(size: subjectFontSize))
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedSubject == subject {
                                Image(systemName: "checkmark")
                                    .font(.system(size: checkmarkSize, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, subjectButtonPaddingVertical)
                        .padding(.horizontal, subjectButtonPaddingHorizontal)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.Layout.largeCardCornerRadius)
                                .fill(selectedSubject == subject ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedSubject == "Other" {
                    TextField("Enter your topic", text: $customSubject)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: inputFontSize))
                        .padding(.top, 8)
                }
            }
        } header: {
            Text("Topic")
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Your Name", text: $name)
                .font(.system(size: inputFontSize))
        } header: {
            Text("Name")
        }
    }

    private var emailSection: some View {
        Section {
            TextField("your@email.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .font(.system(size: inputFontSize))
        } header: {
            Text("Email")
        }
    }

    private var messageSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Describe your feedback...")
                        .font(.system(size: inputFontSize))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $message)
                    .font(.system(size: inputFontSize))
                    .frame(minHeight: messageMinHeight)
            }
        } header: {
            Text("Message")
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                submitFeedback()
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(progressScale)
                    } else {
                        Text("Submit Feedback")
                            .font(.system(size: submitFontSize, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, submitButtonPaddingVertical)
            }
            .disabled(isSubmitting || !isValid)
            .listRowBackground(isValid ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundColor(.white)
        }
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var subjectSpacing: CGFloat {
        isPad ? 12 : 10
    }

    private var iconSize: CGFloat {
        isPad ? 22 : 18
    }

    private var iconFrameWidth: CGFloat {
        isPad ? 28 : 24
    }

    private var subjectFontSize: CGFloat {
        isPad ? 18 : 16
    }

    private var checkmarkSize: CGFloat {
        isPad ? 16 : 13
    }

    private var subjectButtonPaddingVertical: CGFloat {
        isPad ? 14 : 8
    }

    private var subjectButtonPaddingHorizontal: CGFloat {
        isPad ? 16 : 12
    }

    private var inputFontSize: CGFloat {
        isPad ? 18 : 16
    }

    private var messageMinHeight: CGFloat {
        isPad ? 160 : 120
    }

    private var submitFontSize: CGFloat {
        isPad ? 20 : 17
    }

    private var submitButtonPaddingVertical: CGFloat {
        isPad ? 16 : 4
    }

    private var progressScale: CGFloat {
        isPad ? 1.3 : 1.0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var finalSubject: String {
        if selectedSubject == "Other" && !customSubject.isEmpty {
            return customSubject
        }
        return selectedSubject
    }

    private func subjectIcon(_ subject: String) -> String {
        switch subject {
        case "Feature Request": return "lightbulb.fill"
        case "Bug Report": return "ladybug.fill"
        case "Usage Question": return "questionmark.circle.fill"
        case "Performance Issue": return "gauge.with.dots.needle.33percent"
        case "UI Suggestion": return "paintbrush.fill"
        case "Other": return "ellipsis.circle.fill"
        default: return "envelope.fill"
        }
    }

    private func submitFeedback() {
        isSubmitting = true

        FeedbackService.shared.submitFeedback(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: finalSubject,
            message: message.trimmingCharacters(in: .whitespaces)
        ) { result in
            isSubmitting = false
            switch result {
            case .success:
                submitResult = .success
                HapticService.shared.success()
            case .failure(let error):
                submitResult = .failure(error.localizedDescription)
                HapticService.shared.error()
            }
        }
    }
}
