import AppKit
import SwiftUI

/// ウィンドウ本体に対する最小限の設定。
///
/// 信号機ボタン・角丸・影は macOS が描くものをそのまま使う（アプリ側では描かない）。
/// ここで足すのは、タイトルバーが無くても背景をつかんで動かせるようにすることだけ。
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // ビュー階層に入るまで window は nil なので、次のループで設定する。
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
