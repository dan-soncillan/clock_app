import SwiftUI

extension View {
    /// CSS の `letter-spacing: Xem` 相当。em をポイントに直して字送りに渡す。
    func tracking(em: CGFloat, size: CGFloat) -> some View {
        tracking(em * size)
    }

    /// CSS の `line-height` 相当。
    ///
    /// テキスト自体は切り取らず、レイアウト上の高さだけを詰める。
    /// 大きな数字の周りの余白をデザインどおりに保つために使う。
    func lineHeight(_ factor: CGFloat, size: CGFloat) -> some View {
        frame(height: size * factor)
    }
}
