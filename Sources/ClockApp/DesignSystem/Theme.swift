import SwiftUI

/// アプリ全体で使う色・角丸・余白の定義。
/// 見た目を変えたいときはまずここを触る。
enum Theme {
    // MARK: - 色

    /// 時計のアクセント（秒針・強調テキスト）。
    static let accent = Color(red: 0.40, green: 0.62, blue: 1.00)
    static let accentSecondary = Color(red: 0.62, green: 0.45, blue: 1.00)

    static let accentGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// ウインドウ背景。ライト/ダークどちらでも沈みすぎないよう控えめな階調にする。
    static func windowBackground(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(red: 0.07, green: 0.08, blue: 0.11), Color(red: 0.11, green: 0.10, blue: 0.16)]
            : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.90, green: 0.92, blue: 0.97)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// カードの縁取り。ガラス面のハイライトを表現する。
    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.65)
    }

    static func shadow(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.12)
    }

    // MARK: - 形状・余白

    static let cardCornerRadius: CGFloat = 28
    static let cardPadding: CGFloat = 28
    static let contentSpacing: CGFloat = 20

    /// 横並びから縦並びに切り替える幅のしきい値。
    static let stackBreakpoint: CGFloat = 720
}
