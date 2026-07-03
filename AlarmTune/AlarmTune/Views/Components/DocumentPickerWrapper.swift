import SwiftUI
import UniformTypeIdentifiers

/// UIViewControllerRepresentable 包装 UIDocumentPickerViewController
/// 让 SwiftUI 可以调用 Files App 选择音频文件
struct DocumentPickerWrapper: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 使用 UTType.audio 覆盖所有音频格式（mp3/m4a/wav/aiff/caf 等）
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
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
