import ClockCore
import SwiftUI

/// デジタル表示。時・分・秒と日付、タイムゾーンをまとめて見せる。
struct DigitalClockView: View {
    var date: Date
    var formatter: ClockFormatter
    var showsSeconds: Bool

    var body: some View {
        let time = formatter.digitalTime(for: date)

        VStack(alignment: .leading, spacing: 18) {
            timeRow(time)
            Divider().opacity(0.35)
            metadataRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("デジタル時計"))
        .accessibilityValue(Text(date, style: .time))
    }

    private func timeRow(_ time: ClockFormatter.DigitalTime) -> some View {
        // 桁が変わっても幅が動かないよう等幅数字を使い、コロンは別要素にする。
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            digits(time.hour)
            separator
            digits(time.minute)
            if showsSeconds {
                separator
                digits(time.second)
                    .foregroundStyle(Theme.accentGradient)
            }
            if let period = time.period {
                Text(period)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
        }
        .contentTransition(.numericText())
        .animation(.snappy(duration: 0.25), value: time)
        .minimumScaleFactor(0.4)
        .lineLimit(1)
    }

    private func digits(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 76, weight: .semibold, design: .rounded))
            .monospacedDigit()
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 64, weight: .light, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
    }

    private var metadataRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatter.dateText(for: date))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.8))

            Label(formatter.timeZoneText(for: date), systemImage: "globe")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
