import SwiftUI

/// 高さ 44px のタイトルバー。
///
/// 信号機ボタンは macOS 本体が描くもの（`.windowStyle(.hiddenTitleBar)` で
/// コンテンツの上に残る）をそのまま使い、ここでは背景と中央のタイトルだけを置く。
/// 左右のスペーサー幅はデザインと同じで、タイトルが中央に来るよう釣り合わせている。
struct TitleBarView: View {
    var body: some View {
        HStack(spacing: 8) {
            // 実際の信号機ボタンが載る領域。
            Color.clear.frame(width: 57)

            Text("CLOCK")
                .font(AppFont.archivo(size: 11, weight: 600))
                .tracking(em: 0.16, size: 11)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 66)
        }
        .padding(.horizontal, 14)
        .frame(height: Theme.titleBarHeight)
        .background(Theme.chromeBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.borderChrome).frame(height: 1)
        }
    }
}
