import Foundation

/// デジタル表示用の文字列を組み立てる。
///
/// 桁が入れ替わってもレイアウトが揺れないよう、時・分・秒は個別の文字列として
/// 返し、区切りのコロンは View 側で描画する。
public struct ClockFormatter: Sendable {
    public var timeZone: TimeZone
    public var locale: Locale
    /// `true` で 24 時間表記、`false` で 12 時間表記（AM/PM 付き）。
    public var uses24HourClock: Bool

    public init(timeZone: TimeZone = .current, locale: Locale = .current, uses24HourClock: Bool = true) {
        self.timeZone = timeZone
        self.locale = locale
        self.uses24HourClock = uses24HourClock
    }

    /// 分解済みのデジタル表示。
    public struct DigitalTime: Equatable, Sendable {
        public var hour: String
        public var minute: String
        public var second: String
        /// 12 時間表記のときだけ "AM" / "PM" が入る。
        public var period: String?

        public init(hour: String, minute: String, second: String, period: String?) {
            self.hour = hour
            self.minute = minute
            self.second = second
            self.period = period
        }
    }

    public func digitalTime(for date: Date) -> DigitalTime {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let rawHour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        let second = parts.second ?? 0

        if uses24HourClock {
            return DigitalTime(
                hour: Self.twoDigits(rawHour),
                minute: Self.twoDigits(minute),
                second: Self.twoDigits(second),
                period: nil
            )
        }

        let hour12 = rawHour % 12 == 0 ? 12 : rawHour % 12
        return DigitalTime(
            hour: Self.twoDigits(hour12),
            minute: Self.twoDigits(minute),
            second: Self.twoDigits(second),
            period: rawHour < 12 ? "AM" : "PM"
        )
    }

    /// 「2026年8月31日 月曜日」のような、ロケールに沿った日付文字列。
    public func dateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("yMMMMd EEEE")
        return formatter.string(from: date)
    }

    /// ステータス行に出すタイムゾーン名（例: "日本標準時" / "GMT+9"）。
    /// 夏時間の期間はサマータイム側の名称を返す。
    public func timeZoneText(for date: Date) -> String {
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date)
            ? .daylightSaving
            : .standard
        return timeZone.localizedName(for: style, locale: locale) ?? timeZone.identifier
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
