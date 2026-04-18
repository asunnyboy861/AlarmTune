import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
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
    }

    private var subjectSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(subjects, id: \.self) { subject in
                    Button {
                        selectedSubject = subject
                        HapticService.shared.selection()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: subjectIcon(subject))
                                .font(.body)
                                .frame(width: 24)
                                .foregroundColor(selectedSubject == subject ? .accentColor : .secondary)

                            Text(subject)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedSubject == subject {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSubject == subject ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedSubject == "Other" {
                    TextField("Enter your topic", text: $customSubject)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 4)
                }
            }
        } header: {
            Text("Topic")
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Your Name", text: $name)
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
        } header: {
            Text("Email")
        }
    }

    private var messageSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Describe your feedback...")
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $message)
                    .frame(minHeight: 120)
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
                    } else {
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .disabled(isSubmitting || !isValid)
            .listRowBackground(isValid ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundColor(.white)
        }
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
