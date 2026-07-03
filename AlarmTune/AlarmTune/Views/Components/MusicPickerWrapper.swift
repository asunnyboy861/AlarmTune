import SwiftUI
import MediaPlayer

/// UIViewControllerRepresentable 包装 MPMediaPickerController
/// 让 SwiftUI 可以调用系统的音乐库选择器
struct MusicPickerWrapper: UIViewControllerRepresentable {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: MusicPickerWrapper
        init(_ parent: MusicPickerWrapper) { self.parent = parent }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            if let item = mediaItemCollection.items.first {
                let identifier = MusicLibraryService.shared.saveSelectedSong(item)
                parent.selectedSound = identifier
            }
            parent.dismiss()
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            parent.dismiss()
        }
    }
}
