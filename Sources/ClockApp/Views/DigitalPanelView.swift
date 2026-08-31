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
    /// 生年月日が未設定なら nil。値を伏せてバーを空にする。
    var life: LifeProgress?
    var targetAge: Int
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

    /// 時計の右横に置く日付の塊。時刻ブロックと同じ高さに広げて上下をそろえる。
    private var dateInfo: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(formatter.weekdayText(for: date))
                .font(AppFont.archivo(size: 28, weight: 600))
                .tracking(em: 0.02, size: 28)
                .foregroundStyle(Theme.textPrimary)
                .lineHeight(1, size: 28)
            Spacer(minLength: 0)
            Text(formatter.dateText(for: date))
                .font(AppFont.archivo(size: 20, weight: 400))
                .foregroundStyle(Theme.textSecondary)
                .lineHeight(1, size: 20)
            Spacer(minLength: 0)
            Text("WEEK \(progress.weekNumber)")
                .font(AppFont.archivo(size: 14, weight: 500))
                .tracking(em: 0.12, size: 14)
                .foregroundStyle(Theme.textLabel)
                .lineHeight(1, size: 14)
        }
        .frame(height: 104 * 0.82)
    }

    // MARK: - 残量のセクション

    /// 残量セクション。残りの高さを全部使い、グループ間に余白を均等配分する。
    private var remaindersBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // 今日だけ大きな数字で。ラベルと同じ行に置き、上端をそろえる。
                HStack(alignment: .top, spacing: 16) {
                    sectionLabel("REMAINING TODAY")
                        .padding(.top, 6)
                        .fixedSize()
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: 26) {
                        bigValue(progress.remainingTodayText)
                        bigValue(percentText(progress.dayRemainingFraction))
                    }
                }
                RemainingBar(fraction: progress.dayRemainingFraction, accent: accent)
                AxisLabels(labels: ["24", "18", "12", "06", "0"])
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                compactRow("REMAINING IN MONTH", progress.remainingMonthText, progress.monthRemainingFraction)
                RemainingBar(fraction: progress.monthRemainingFraction, accent: accent)
                AxisLabels(labels: progress.monthAxisMilestones.map(String.init))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                compactRow("REMAINING IN YEAR", progress.remainingYearText, progress.yearRemainingFraction)
                RemainingBar(fraction: progress.yearRemainingFraction, accent: accent)
                AxisLabels(labels: progress.yearAxisMilestones.map(String.init))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                compactRow(
                    "REMAINING TO AGE \(targetAge)",
                    life?.remainingText ?? "—",
                    percent: life.map { percentText($0.remainingFraction) } ?? "—"
                )
                RemainingBar(fraction: life?.remainingFraction ?? 0, accent: accent)
                AxisLabels(labels: LifeProgress.axisMilestones(targetAge: targetAge).map(String.init))
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func compactRow(_ label: String, _ value: String, _ fraction: Double) -> some View {
        compactRow(label, value, percent: percentText(fraction))
    }

    private func compactRow(_ label: String, _ value: String, percent: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            sectionLabel(label)
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(value)
                Text(percent)
            }
            .font(AppFont.archivo(size: 15, weight: 600))
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
        }
    }

    private func bigValue(_ text: String) -> some View {
        Text(text)
            .font(AppFont.archivo(size: 60, weight: 600))
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
            // ネイティブ版のカラムは Web より少し狭いので、
            // 入り切らないときは truncation ではなく縮小で収める。
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .lineHeight(0.9, size: 60)
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
