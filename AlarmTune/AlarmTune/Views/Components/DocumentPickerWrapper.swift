import SwiftUI
import UniformTypeIdentifiers

/// UIViewControllerRepresentable 包装 UIDocumentPickerViewController
/// 让 SwiftUI 可以调用 Files App 选择音频或视频文件
///
/// P0 fix: 添加 contentType 参数，支持视频文件导入
///
/// I4 文档说明：UTType.audio 的 iOS 行为
/// -----------------------------------------------
/// UTType.audio 是抽象类型，理论上包含 UTType.mp3、UTType.mpeg4Audio 等所有音频子类型。
/// 但在 iOS Files App 中，部分 MP3 文件可能因以下原因不在选择器中显示：
///   1. 文件 UTI 元数据缺失（从 Safari 下载的部分文件）
///   2. 文件扩展名非标准（如 .mpeg3 而非 .mp3）
///   3. 文件存储在 iCloud Drive 但尚未下载到本地
///
/// 已知限制无法通过代码完全解决，通过以下方式缓解：
///   - I3 在 Import 按钮旁显示支持格式提示，让用户知道支持 MP3
///   - I2 在导入失败时给出精准错误提示
///   - 用户引导：若文件不可见，建议在 Files App 中长按文件 → 共享 → 存储到"在我的 iPhone 上"
struct DocumentPickerWrapper: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    // 修复：UTType.audio 过滤会导致 UTI 元数据缺失的 MP3 文件不可见
    // 添加 UTType.data 作为 fallback，让所有文件可见
    // SoundImportService.importFileWithError 的格式校验会拦截不支持的格式
    var contentTypes: [UTType] = [UTType.audio, UTType.data]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerWrapper
        init(_ parent: DocumentPickerWrapper) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPick(url)
            }
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
