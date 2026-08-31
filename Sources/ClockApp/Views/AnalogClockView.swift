import ClockCore
import SwiftUI

/// アナログ時計の文字盤。
///
/// 時刻は親から受け取るだけで、自前ではタイマーを持たない。
/// これでデジタル表示と同じフレームの時刻を共有できる。
struct AnalogClockView: View {
    @Environment(\.colorScheme) private var colorScheme

    var date: Date
    var timeZone: TimeZone
    var showsSeconds: Bool
    var sweepingSeconds: Bool
    var showsNumerals: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let hands = ClockHands(date: date, timeZone: timeZone, sweepingSeconds: sweepingSeconds)

            ZStack {
                face(size: size)
                ticks(size: size)
                if showsNumerals {
                    numerals(size: size)
                }
                hourHand(size: size, angle: hands.hour)
                minuteHand(size: size, angle: hands.minute)
                if showsSeconds {
                    secondHand(size: size, angle: hands.second)
                }
                hub(size: size)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("アナログ時計"))
        .accessibilityValue(Text(date, style: .time))
    }

    // MARK: - 文字盤

    private func face(size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                        : [Color.white.opacity(0.95), Color.white.opacity(0.55)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .overlay(
                Circle().strokeBorder(Theme.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: Theme.shadow(for: colorScheme), radius: 18, x: 0, y: 8)
    }

    private func ticks(size: CGFloat) -> some View {
        ForEach(0..<60, id: \.self) { index in
            let isHour = index % 5 == 0
            Capsule()
                .fill(Color.primary.opacity(isHour ? 0.65 : 0.18))
                .frame(
                    width: isHour ? size * 0.012 : size * 0.006,
                    height: isHour ? size * 0.055 : size * 0.028
                )
                .offset(y: -size / 2 + size * 0.062)
                .rotationEffect(.degrees(Double(index) * 6))
        }
    }

    private func numerals(size: CGFloat) -> some View {
        ForEach(1...12, id: \.self) { hour in
            let angle = Double(hour) * 30
            Text("\(hour)")
                .font(.system(size: size * 0.085, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(0.75))
                // 先に打ち消しておくと、外側の回転で配置だけが動き文字は水平のまま残る。
                .rotationEffect(.degrees(-angle))
                .offset(y: -size / 2 + size * 0.155)
                .rotationEffect(.degrees(angle))
        }
    }

    // MARK: - 針

    private func hourHand(size: CGFloat, angle: Double) -> some View {
        hand(
            length: size * 0.28,
            width: size * 0.028,
            style: AnyShapeStyle(Color.primary.opacity(0.85)),
            angle: angle
        )
    }

    private func minuteHand(size: CGFloat, angle: Double) -> some View {
        hand(
            length: size * 0.40,
            width: size * 0.020,
            style: AnyShapeStyle(Color.primary.opacity(0.75)),
            angle: angle
        )
    }

    private func secondHand(size: CGFloat, angle: Double) -> some View {
        // 中心を挟んで短い尾（カウンターウェイト）を残すと本物らしいバランスになる。
        Capsule()
            .fill(Theme.accentGradient)
            .frame(width: size * 0.010, height: size * 0.53)
            .offset(y: -size * 0.53 / 2 + size * 0.07)
            .rotationEffect(.degrees(angle))
            .shadow(color: Theme.accent.opacity(0.35), radius: 6)
    }

    private func hand(length: CGFloat, width: CGFloat, style: AnyShapeStyle, angle: Double) -> some View {
        Capsule()
            .fill(style)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }

    private func hub(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Theme.accentGradient)
                .frame(width: size * 0.045, height: size * 0.045)
            Circle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: size * 0.018, height: size * 0.018)
        }
    }
}
