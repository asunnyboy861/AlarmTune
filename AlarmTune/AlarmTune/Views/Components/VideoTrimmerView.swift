import SwiftUI
import AVKit

/// 视频截取组件（M8.2 MVP）
///
/// MVP 方案：包装系统 UIVideoEditorController
/// - 开箱即用，符合 iOS 习惯
/// - 限制最长 30 秒（闹钟视频不需要过长）
/// - 后期可升级为基于 AVFoundation 的自定义截取器
struct VideoTrimmerView: UIViewControllerRepresentable {
    let sourceURL: URL
    let onTrimmed: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIVideoEditorController {
        let editor = UIVideoEditorController()
        editor.videoPath = sourceURL.path  // videoPath 是 String 类型
        editor.videoMaximumDuration = 30.0  // 闹钟视频最长 30 秒
        editor.delegate = context.coordinator
        return editor
    }

    func updateUIViewController(_ uiViewController: UIVideoEditorController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoTrimmerView

        init(_ parent: VideoTrimmerView) {
            self.parent = parent
        }

        func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
            let url = URL(fileURLWithPath: editedVideoPath)
            editor.dismiss(animated: true) {
                self.parent.onTrimmed(url)
            }
        }

        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
            editor.dismiss(animated: true) {
                self.parent.onCancel()
            }
        }

        func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
            print("Video editing failed: \(error.localizedDescription)")
            editor.dismiss(animated: true) {
                self.parent.onCancel()
            }
        }
    }
}
