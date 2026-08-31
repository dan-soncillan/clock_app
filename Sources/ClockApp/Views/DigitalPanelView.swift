import ClockCore
import SwiftUI

/// 右側のデジタル情報カラム。
///
/// 「現在」ブロックと「日付・年」ブロックを 1px の区切り線で分ける。
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
            nowBlock
            Rectangle()
                .fill(Theme.borderStrong)
                .frame(height: 1)
            dateBlock
            Rectangle()
                .fill(Theme.borderStrong)
                .frame(height: 1)
            lifeBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ブロック1「現在」

    private var nowBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatter.timeZoneText(for: date))
                .font(AppFont.archivo(size: 11, weight: 600))
                .tracking(em: 0.18, size: 11)
                .foregroundStyle(Theme.textTertiary)

            timeRow

            HStack(alignment: .firstTextBaseline) {
                sectionLabel("REMAINING TODAY")
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(progress.remainingTodayText)
                    Text(smallPercentText(progress.dayRemainingFraction))
                }
                .font(AppFont.archivo(size: 15, weight: 600))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            }

            RemainingBar(fraction: progress.dayRemainingFraction, accent: accent)
            AxisLabels(labels: ["24", "18", "12", "06", "0"])
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("デジタル時計"))
        .accessibilityValue(Text(date, style: .time))
    }

    private var timeRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(formatter.hourMinuteText(for: date))
                .font(AppFont.archivo(size: 104, weight: weight))
                .tracking(em: -0.05, size: 104)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineHeight(0.82, size: 104)

            if showSeconds {
                Text(formatter.secondText(for: date))
                    .font(AppFont.archivo(size: 36, weight: weight))
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }

            if let period = formatter.periodText(for: date) {
                Text(period)
                    .font(AppFont.archivo(size: 22, weight: 600))
                    .tracking(em: 0.08, size: 22)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - ブロック2「日付・年」

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 曜日と日付は 1 行に。文字の大きさと色の差で読み分ける。
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatter.weekdayText(for: date))
                    .font(AppFont.archivo(size: 20, weight: 600))
                    .tracking(em: 0.02, size: 20)
                    .foregroundStyle(Theme.textPrimary)
                Text(formatter.dateText(for: date))
                    .font(AppFont.archivo(size: 15, weight: 400))
                    .foregroundStyle(Theme.textSecondary)
            }

            Text("WEEK \(progress.weekNumber) · DAY \(progress.dayOfYear) OF \(progress.daysInYear)")
                .font(AppFont.archivo(size: 11, weight: 500))
                .tracking(em: 0.12, size: 11)
                .foregroundStyle(Theme.textLabel)

            sectionLabel("REMAINING IN \(progress.year)")
                .padding(.top, 4)

            HStack(alignment: .firstTextBaseline, spacing: 26) {
                remainingValue(progress.weeksRemaining, unit: "WEEKS")
                remainingValue(progress.daysRemaining, unit: "DAYS")
                percentLabel(progress.yearRemainingFraction)
            }

            RemainingBar(fraction: progress.yearRemainingFraction, accent: accent)
            // 上の残時間バーと同じく、右に向かって 0 に近づく残り日数の目盛り。
            AxisLabels(labels: progress.yearAxisMilestones.map(String.init))
        }
    }

    // MARK: - ブロック3「生涯の残り」

    private var lifeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("REMAINING TO AGE \(life.targetAge)")

            HStack(alignment: .firstTextBaseline, spacing: 26) {
                remainingValue(life.yearsRemaining, unit: "YEARS")
                remainingValue(life.daysRemaining, unit: "DAYS", grouped: true)
                percentLabel(life.remainingFraction)
            }

            RemainingBar(fraction: life.remainingFraction, accent: accent)
            AxisLabels(labels: life.axisMilestones.map(String.init))
        }
    }

    private func remainingValue(_ value: Int, unit: String, grouped: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            // 桁数の多い日数だけ 3 桁区切りを入れる。
            Text(grouped ? value.formatted(.number.grouping(.automatic)) : "\(value)")
                .font(AppFont.archivo(size: 40, weight: 600))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineHeight(0.9, size: 40)
            Text(unit)
                .font(AppFont.archivo(size: 12, weight: 500))
                .tracking(em: 0.14, size: 12)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func smallPercentText(_ fraction: Double) -> String {
        "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }

    /// バーが示す残りの割合。隣の日数と同じ大きさで並べる。
    private func percentLabel(_ fraction: Double) -> some View {
        let percent = Int((min(max(fraction, 0), 1) * 100).rounded())
        return Text("\(percent)%")
            .font(AppFont.archivo(size: 40, weight: 600))
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
            .lineHeight(0.9, size: 40)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.archivo(size: 10, weight: 600))
            .tracking(em: 0.22, size: 10)
            .foregroundStyle(Theme.textLabel)
    }
}
