import SwiftUI

/// AI 铃声生成页面（M8.3 MVP）
///
/// MVP 方案：用户选择风格 → 设备端合成 → 保存为导入铃声
/// 未来可扩展为：文本描述 → 后端 AI 模型 → 生成专业铃声
struct AIAlarmGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var prompt: String = ""
    @State private var selectedStyle: AIGenerationService.AIGenStyle = .calm
    @State private var isGenerating: Bool = false
    @State private var generatedSoundId: String?
    @State private var errorMessage: String?
    @State private var showSuccessAlert: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    promptSection
                    styleSelectionSection
                    generateButton
                    if let error = errorMessage {
                        errorView(error)
                    }
                }
                .padding()
                .frame(maxWidth: maxContentWidth)
            }
            .navigationTitle("AI Sound Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Sound Generated!", isPresented: $showSuccessAlert) {
                Button("Use This Sound") {
                    if let soundId = generatedSoundId {
                        NotificationCenter.default.post(
                            name: .aiSoundGenerated,
                            object: nil,
                            userInfo: ["soundId": soundId]
                        )
                    }
                    dismiss()
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your AI-generated sound has been saved to Imported Sounds.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: isPad ? 56 : 44))
                .foregroundColor(.purple)

            Text("Generate Custom Sound")
                .font(.system(size: isPad ? 24 : 20, weight: .bold))

            Text("Pick a style and give your sound a name. AI will generate a unique tone based on the selected style.")
                .font(.system(size: isPad ? 16 : 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name Your Sound")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            TextField("e.g., Gentle Morning Breeze", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .font(.system(size: 16))
        }
    }

    // MARK: - Style Selection

    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(AIGenerationService.AIGenStyle.allCases) { style in
                    styleCard(style)
                }
            }
        }
    }

    private func styleCard(_ style: AIGenerationService.AIGenStyle) -> some View {
        Button {
            selectedStyle = style
            HapticService.shared.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: isPad ? 24 : 20))
                    .foregroundColor(styleColor(style))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.system(size: isPad ? 17 : 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(style.description)
                        .font(.system(size: isPad ? 14 : 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedStyle == style {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 22))
                }
            }
            .padding()
            .background(selectedStyle == style ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedStyle == style ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func styleColor(_ style: AIGenerationService.AIGenStyle) -> Color {
        switch style {
        case .calm:      return .blue
        case .energetic: return .orange
        case .nature:    return .green
        case .retro:     return .purple
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generateSound()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate Sound")
                }
            }
            .font(.system(size: isPad ? 18 : 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPad ? 16 : 14)
            .background(isGenerating ? Color.gray : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
        }
        .disabled(isGenerating)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func generateSound() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let soundId = try await AIGenerationService.shared.generateSound(
                    prompt: prompt.isEmpty ? "Custom" : prompt,
                    style: selectedStyle
                )

                await MainActor.run {
                    self.isGenerating = false
                    self.generatedSoundId = soundId
                    self.showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Layout

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var maxContentWidth: CGFloat {
        isPad ? 600 : AppConstants.Layout.maxContentWidth
    }
}

// MARK: - Notification

extension Notification.Name {
    static let aiSoundGenerated = Notification.Name("aiSoundGenerated")
}
