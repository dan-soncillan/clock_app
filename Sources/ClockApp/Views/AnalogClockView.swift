import ClockCore
import SwiftUI

/// 512 × 512 の文字盤。
///
/// 時刻は親から受け取るだけで、自前ではタイマーを持たない。
/// これでデジタル表示と必ず同じ瞬間を描ける。
struct AnalogClockView: View {
    /// 文字盤の半径。位置指定はすべてこの値を基準にする。
    private static let radius = Theme.dialSize / 2
    /// 目盛りの外端と円周のすきま。
    private static let tickInset: CGFloat = 10
    /// 中心から数字の中心までの距離。
    private static let numeralRadius: Double = 194

    var date: Date
    var timeZone: TimeZone
    var showSeconds: Bool
    var smoothSweep: Bool
    var weight: Int
    var accent: Color

    var body: some View {
        let hands = ClockHands(date: date, timeZone: timeZone, sweepingSeconds: smoothSweep)

        ZStack {
            Circle()
                .fill(Theme.dialGradient)
                .overlay(Circle().strokeBorder(Theme.borderStrong, lineWidth: 1))

            ticks
            numerals

            hand(width: 10, length: 112, cornerRadius: 5, color: Theme.textPrimary, angle: hands.hour)
            hand(width: 6, length: 158, cornerRadius: 3, color: Theme.textPrimary, angle: hands.minute)
            if showSeconds {
                hand(width: 2, length: 168, cornerRadius: 0, color: accent, angle: hands.second)
            }
            // 中心のキャップは意図的に置かない。
        }
        .frame(width: Theme.dialSize, height: Theme.dialSize)
        .accessibilityElement()
        .accessibilityLabel(Text("アナログ時計"))
        .accessibilityValue(Text(date, style: .time))
    }

    /// 60 本の目盛り。5 分ごとだけ太く長い。
    private var ticks: some View {
        ForEach(0..<60, id: \.self) { index in
            let isMajor = index % 5 == 0
            let height: CGFloat = isMajor ? 16 : 8
            Rectangle()
                .fill(isMajor ? Theme.tickMajor : Theme.tickMinor)
                .frame(width: isMajor ? 3 : 1, height: height)
                .offset(y: -(Self.radius - Self.tickInset - height / 2))
                .rotationEffect(.degrees(Double(index) * 6))
        }
    }

    /// 12 個の数字。半径 194px の円周上に、向きは変えず水平のまま置く。
    private var numerals: some View {
        ForEach(0..<12, id: \.self) { index in
            let angle = Double(index) / 12 * 2 * Double.pi - Double.pi / 2
            Text("\(index == 0 ? 12 : index)")
                .font(AppFont.archivo(size: 42, weight: weight))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .offset(
                    x: CGFloat((cos(angle) * Self.numeralRadius).rounded()),
                    y: CGFloat((sin(angle) * Self.numeralRadius).rounded())
                )
        }
    }

    /// 中心から上方向に伸ばして回転させる針。
    private func hand(
        width: CGFloat,
        length: CGFloat,
        cornerRadius: CGFloat,
        color: Color,
        angle: Double
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}
