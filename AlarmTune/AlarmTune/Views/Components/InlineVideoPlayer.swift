import SwiftUI
import AVKit

/// 轻量级内联视频播放器，基于 AVPlayerLayer
///
/// 替代 SwiftUI 的 VideoPlayer，解决后者在 Button 标签内不渲染视频的问题。
/// AVPlayerLayer 直接挂在 UIView.layer 上，不受 SwiftUI 视图层级影响。
struct InlineVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    /// 容器视图：layerClass 设为 AVPlayerLayer
    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
