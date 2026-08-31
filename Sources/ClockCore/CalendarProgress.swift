import Foundation

/// 「今日の残り」「今年の残り」を表す派生値。
///
/// デザインハンドオフの定義に一対一で対応させてある。
/// - `remainingMinutesToday` = `1440 - (hour * 60 + minute)`
/// - `dayOfYear` = 元日からの経過日数 + 1
/// - `weekNumber` = `ceil(dayOfYear / 7)`
/// - `weeksRemaining` = `floor(daysRemaining / 7)`
public struct CalendarProgress: Equatable, Sendable {
    public var year: Int
    /// 今日の残り時間（分）。0:00 ちょうどなら 1440。
    public var remainingMinutesToday: Int
    /// 元日を 1 とした通日。
    public var dayOfYear: Int
    /// その年の日数（365 または 366）。
    public var daysInYear: Int
    /// 今年の残り日数。
    public var daysRemaining: Int
    /// 今年の残り週数（切り捨て）。
    public var weeksRemaining: Int
    /// 第何週か（切り上げ）。
    public var weekNumber: Int

    /// 残時間バーの塗り幅（0...1）。
    public var dayRemainingFraction: Double {
        Double(remainingMinutesToday) / 1440
    }

    /// 残日数バーの塗り幅（0...1）。
    public var yearRemainingFraction: Double {
        Double(daysRemaining) / Double(daysInYear)
    }

    /// 残り日数バーの目盛り。4 等分した位置に置く値を左から返す。
    ///
    /// バーは線形なので、きりのいい数字に丸めず位置どおりの値を出す。
    /// 例: 365 日の年なら `[365, 274, 183, 91, 0]`。
    public var yearAxisMilestones: [Int] {
        stride(from: 4, through: 0, by: -1).map { step in
            Int((Double(daysInYear) * Double(step) / 4).rounded())
        }
    }

    /// 残り時間の表示文字列。時刻と同じ「時:分」の形で出す（例: `12:35`）。
    /// 0:00 ちょうどは丸一日残っているので `24:00`。
    public var remainingTodayText: String {
        let hours = remainingMinutesToday / 60
        let minutes = remainingMinutesToday % 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    public init(date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let parts = calendar.dateComponents([.year, .hour, .minute], from: date)
        year = parts.year ?? 0
        remainingMinutesToday = 1440 - ((parts.hour ?? 0) * 60 + (parts.minute ?? 0))

        dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        daysRemaining = daysInYear - dayOfYear
        weeksRemaining = daysRemaining / 7
        weekNumber = Int((Double(dayOfYear) / 7).rounded(.up))
    }
}
