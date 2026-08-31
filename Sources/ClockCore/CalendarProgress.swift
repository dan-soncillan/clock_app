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
    /// 今週の残り分。週は月曜 0:00 に始まり、次の月曜 0:00 で終わる。
    public var remainingMinutesInWeek: Int
    /// 今月の日数（28〜31）。
    public var daysInMonth: Int
    /// 今月の残り分。
    public var remainingMinutesInMonth: Int

    /// 残時間バーの塗り幅（0...1）。
    public var dayRemainingFraction: Double {
        Double(remainingMinutesToday) / 1440
    }

    /// 残日数バーの塗り幅（0...1）。
    public var yearRemainingFraction: Double {
        Double(daysRemaining) / Double(daysInYear)
    }

    /// 今週の残りバーの塗り幅（0...1）。1 週間は 10,080 分。
    public var weekRemainingFraction: Double {
        Double(remainingMinutesInWeek) / 10_080
    }

    /// 今週の残りの表示文字列（例: `6D 08:40`）。
    public var remainingWeekText: String {
        let days = remainingMinutesInWeek / 1440
        let rest = remainingMinutesInWeek % 1440
        return String(format: "%dD %02d:%02d", days, rest / 60, rest % 60)
    }

    /// 今週の残りバーの目盛り。1 日刻みで 7 から 0 まで。
    public var weekAxisMilestones: [Int] {
        Array(stride(from: 7, through: 0, by: -1))
    }

    /// 今月の残りバーの塗り幅（0...1）。
    public var monthRemainingFraction: Double {
        Double(remainingMinutesInMonth) / Double(daysInMonth * 1440)
    }

    /// 今月の残りの表示文字列。日数だけを出す（例: `13D`）。
    public var remainingMonthText: String {
        "\(remainingMinutesInMonth / 1440)D"
    }

    /// 今月の残りバーの目盛り。月の日数を 4 等分した位置の値。
    public var monthAxisMilestones: [Int] {
        stride(from: 4, through: 0, by: -1).map { step in
            Int((Double(daysInMonth) * Double(step) / 4).rounded())
        }
    }

    /// 今年の残りの表示文字列（例: `17W | 122D`）。
    /// 週と日は同じ残りの別表現なので、合算と誤読されないよう区切りを入れる。
    public var remainingYearText: String {
        "\(weeksRemaining)W | \(daysRemaining)D"
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

        let parts = calendar.dateComponents([.year, .day, .hour, .minute], from: date)
        year = parts.year ?? 0
        remainingMinutesToday = 1440 - ((parts.hour ?? 0) * 60 + (parts.minute ?? 0))

        // weekday は 1=日曜〜7=土曜。次の月曜 0:00 までの日数に読み替える。
        let weekday = calendar.component(.weekday, from: date)
        var daysToMonday = (9 - weekday) % 7
        if daysToMonday == 0 { daysToMonday = 7 }
        remainingMinutesInWeek = daysToMonday * 1440 - ((parts.hour ?? 0) * 60 + (parts.minute ?? 0))

        daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        remainingMinutesInMonth = (daysInMonth - (parts.day ?? 1)) * 1440 + remainingMinutesToday

        dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        daysRemaining = daysInYear - dayOfYear
        weeksRemaining = daysRemaining / 7
        weekNumber = Int((Double(dayOfYear) / 7).rounded(.up))
    }
}
