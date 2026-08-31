import SwiftUI

/// デザインハンドオフの確定値。数値・色はここだけに置く。
enum Theme {
    // MARK: - 基準サイズ

    /// デザイン基準のウィンドウサイズ。レイアウトはこの座標系で組み、
    /// 実ウィンドウにはまとめて拡大縮小をかける。
    static let canvasSize = CGSize(width: 980, height: 620)
    /// 縮小の下限（デザイン指定は 0.7 倍程度まで）。
    static let minimumScale: CGFloat = 0.7

    static let titleBarHeight: CGFloat = 44
    static let footerHeight: CGFloat = 46
    static let dialSize: CGFloat = 512

    // MARK: - 色

    static let windowBackground = Color(hex: 0x141618)
    static let chromeBackground = Color(hex: 0x17191c)

    static let dialGradient = RadialGradient(
        colors: [Color(hex: 0x1c1f22), Color(hex: 0x131518)],
        center: UnitPoint(x: 0.5, y: 0.3),
        startRadius: 0,
        endRadius: dialSize * 0.75
    )

    static let borderStrong = Color.white.opacity(0.14)
    static let borderWindow = Color.white.opacity(0.12)
    static let borderChrome = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xc3c9ce)
    static let textTertiary = Color(hex: 0x969da3)
    static let textLabel = Color(hex: 0x7d848a)
    static let textAxis = Color(hex: 0x6f767c)
    static let textFooter = Color(hex: 0x8b9298)

    static let tickMajor = Color.white
    static let tickMinor = Color.white.opacity(0.4)

    static let barTrack = Color.white.opacity(0.1)
    static let segmentTrack = Color.white.opacity(0.06)
    static let segmentHover = Color.white.opacity(0.12)

    // MARK: - 角丸

    static let barCornerRadius: CGFloat = 2
    static let segmentCornerRadius: CGFloat = 8
    static let segmentItemCornerRadius: CGFloat = 6
}

extension Color {
    /// `0xRRGGBB` からの生成。デザイントークンをそのまま書き写すために使う。
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}
