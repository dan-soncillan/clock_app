import ClockCore
import SwiftUI

/// 右側のデジタル情報カラム。
///
/// 上が時計のセクション（時刻と日付）、区切り線を1本はさんで、
/// 下が残量のセクション（今日・今週・今月・今年・生涯の5本のバー）。
/// 今日だけを大きな数字で出す。いちばん動きが速く、いちばん見る値だから。
struct DigitalPanelView: View {
    var date: Date
    var formatter: ClockFormatter
    var progress: CalendarProgress
    var life: LifeProgress
    var showSeconds: Bool
    var weight: Int
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            clockBlock

            // 区切り線はここ1本だけ。時計と残量のセクションを分ける。
            Rectangle()
                .fill(Theme.borderStrong)
                .frame(height: 1)

            remaindersBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 時計のセクション

    private var clockBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatter.timeZoneText(for: date))
                .font(AppFont.archivo(size: 11, weight: 600))
                .tracking(em: 0.18, size: 11)
                .foregroundStyle(Theme.textTertiary)

            HStack(alignment: .center, spacing: 16) {
                timeRow
                Spacer(minLength: 0)
                dateInfo
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("デジタル時計"))
        .accessibilityValue(Text(date, style: .time))
    }

    private var timeRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text(formatter.hourMinuteText(for: date))
                .font(AppFont.archivo(size: 104, weight: weight))
                .tracking(em: -0.05, size: 104)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineHeight(0.82, size: 104)

            // AM/PM は秒の上に積む。横に並べると 12 時間表記のとき行が伸びて
            // 右の日付情報が入らなくなる。
            VStack(alignment: .leading, spacing: 6) {
                if let period = formatter.periodText(for: date) {
                    Text(period)
                        .font(AppFont.archivo(size: 22, weight: 600))
                        .tracking(em: 0.08, size: 22)
                        .foregroundStyle(Theme.textTertiary)
                }
                if showSeconds {
                    Text(formatter.secondText(for: date))
                        .font(AppFont.archivo(size: 36, weight: weight))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                }
            }
            .padding(.bottom, 2)
        }
    }

    /// 時計の右横に置く日付の塊。
    private var dateInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatter.weekdayText(for: date))
                .font(AppFont.archivo(size: 20, weight: 600))
                .tracking(em: 0.02, size: 20)
                .foregroundStyle(Theme.textPrimary)
            Text(formatter.dateText(for: date))
                .font(AppFont.archivo(size: 15, weight: 400))
                .foregroundStyle(Theme.textSecondary)
            Text("WEEK \(progress.weekNumber)")
                .font(AppFont.archivo(size: 11, weight: 500))
                .tracking(em: 0.12, size: 11)
                .foregroundStyle(Theme.textLabel)
        }
    }

    // MARK: - 残量のセクション

    private var remaindersBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 今日だけ大きな数字で。
            sectionLabel("REMAINING TODAY")
            HStack(alignment: .firstTextBaseline, spacing: 26) {
                bigValue(progress.remainingTodayText)
                bigValue(percentText(progress.dayRemainingFraction))
            }
            RemainingBar(fraction: progress.dayRemainingFraction, accent: accent)
            AxisLabels(labels: ["24", "18", "12", "06", "0"])

            compactRow("REMAINING IN WEEK", progress.remainingWeekText, progress.weekRemainingFraction)
            RemainingBar(fraction: progress.weekRemainingFraction, accent: accent)
            AxisLabels(labels: progress.weekAxisMilestones.map(String.init))

            compactRow("REMAINING IN MONTH", progress.remainingMonthText, progress.monthRemainingFraction)
            RemainingBar(fraction: progress.monthRemainingFraction, accent: accent)
            AxisLabels(labels: progress.monthAxisMilestones.map(String.init))

            compactRow("REMAINING IN YEAR", progress.remainingYearText, progress.yearRemainingFraction)
            RemainingBar(fraction: progress.yearRemainingFraction, accent: accent)
            AxisLabels(labels: progress.yearAxisMilestones.map(String.init))

            compactRow("REMAINING TO AGE \(life.targetAge)", life.remainingText, life.remainingFraction)
            RemainingBar(fraction: life.remainingFraction, accent: accent)
            AxisLabels(labels: life.axisMilestones.map(String.init))
        }
    }

    private func compactRow(_ label: String, _ value: String, _ fraction: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            sectionLabel(label)
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(value)
                Text(percentText(fraction))
            }
            .font(AppFont.archivo(size: 15, weight: 600))
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
        }
    }

    private func bigValue(_ text: String) -> some View {
        Text(text)
            .font(AppFont.archivo(size: 40, weight: 600))
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
            .lineHeight(0.9, size: 40)
    }

    private func percentText(_ fraction: Double) -> String {
        "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.archivo(size: 10, weight: 600))
            .tracking(em: 0.22, size: 10)
            .foregroundStyle(Theme.textLabel)
    }
}
