import SwiftUI
import UniformTypeIdentifiers

/// UIViewControllerRepresentable 包装 UIDocumentPickerViewController
/// 让 SwiftUI 可以调用 Files App 选择音频或视频文件
///
/// P0 fix: 添加 contentType 参数，支持视频文件导入
struct DocumentPickerWrapper: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    var contentTypes: [UTType] = [UTType.audio]  // P0 fix: 默认音频，视频选择器传入 .video
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
