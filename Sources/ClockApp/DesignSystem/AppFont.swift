import AppKit
import CoreText
import SwiftUI

/// バンドルした Archivo（可変フォント）を、太さを指定して取り出す。
///
/// Archivo は wght 軸を持つ可変フォントなので、`Font.weight(_:)` の記号的な
/// 指定ではなく軸の値を直接与える。500 / 600 のような中間ウェイトも
/// デザイン指定どおりに出せる。
enum AppFont {
    /// 可変フォントの重み軸 `wght` の識別子（4 文字コードを数値化したもの）。
    private static let weightAxis = 0x77676874

    private static let familyName = "Archivo"

    static func archivo(size: CGFloat, weight: Int) -> Font {
        let descriptor = NSFontDescriptor(fontAttributes: [
            .family: familyName,
            NSFontDescriptor.AttributeName(kCTFontVariationAttribute as String): [
                weightAxis: weight
            ]
        ])

        if let font = NSFont(descriptor: descriptor, size: size) {
            return Font(font)
        }
        // フォントを読み込めない環境ではシステムフォントに落とす。
        return .system(size: size, weight: fallbackWeight(for: weight))
    }

    private static func fallbackWeight(for weight: Int) -> Font.Weight {
        switch weight {
        case ..<450: return .regular
        case ..<550: return .medium
        case ..<650: return .semibold
        case ..<750: return .bold
        default: return .heavy
        }
    }
}

/// バンドル同梱のフォントをプロセスに登録する。
///
/// `.app` バンドルでも `swift run` でも同じ経路で読めるよう、
/// Info.plist ではなく起動時の明示的な登録で扱う。
enum FontRegistrar {
    static func registerBundledFonts() {
        guard let url = Bundle.module.url(
            forResource: "Archivo-VariableFont_wdth_wght",
            withExtension: "ttf",
            subdirectory: "Fonts"
        ) else {
            warn("同梱フォントが見つかりません。システムフォントで表示します。")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            let reason = error?.takeRetainedValue().localizedDescription ?? "原因不明"
            warn("同梱フォントを登録できません（\(reason)）。システムフォントで表示します。")
        }
    }

    /// 起動時に気づけるよう標準エラーに出す。フォントの読み込み確認に使う。
    private static func warn(_ message: String) {
        FileHandle.standardError.write(Data("[ClockApp] \(message)\n".utf8))
    }
}
