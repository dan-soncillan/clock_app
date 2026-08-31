import Foundation

/// デジタル表示に必要な文字列を組み立てる。
///
/// 時刻は `HH:MM` と `SS` に分けて返す。デザイン上この 2 つは
/// サイズも色も異なる別要素なので、View 側で連結しない前提。
public struct ClockFormatter: Sendable {
    public var timeZone: TimeZone
    /// 曜日・日付の表記に使うロケール。デザイン指定は `en_US`。
    public var locale: Locale
    /// `true` で 24 時間表記、`false` で 12 時間表記。
    public var uses24HourClock: Bool

    public init(
        timeZone: TimeZone = .current,
        locale: Locale = Locale(identifier: "en_US"),
        uses24HourClock: Bool = true
    ) {
        self.timeZone = timeZone
        self.locale = locale
        self.uses24HourClock = uses24HourClock
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        return calendar
    }

    /// 大きく表示する `HH:MM`。
    ///
    /// 12 時間表記でも桁数を変えない（`01`〜`12`）。デザインが等幅数字を
    /// 前提にしているため、桁数が揺れると隣の秒の位置が動いてしまう。
    public func hourMinuteText(for date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let rawHour = parts.hour ?? 0
        let hour = uses24HourClock ? rawHour : (rawHour % 12 == 0 ? 12 : rawHour % 12)
        return "\(Self.twoDigits(hour)):\(Self.twoDigits(parts.minute ?? 0))"
    }

    /// 12 時間表記のときだけ返す `AM` / `PM`。
    ///
    /// これが無いと 12 時間表記で午前と午後を区別できない。
    public func periodText(for date: Date) -> String? {
        guard !uses24HourClock else { return nil }
        return calendar.component(.hour, from: date) < 12 ? "AM" : "PM"
    }

    /// アクセント色で添える `SS`。
    public func secondText(for date: Date) -> String {
        Self.twoDigits(calendar.component(.second, from: date))
    }

    /// 曜日（大文字）。例: `MONDAY`
    public func weekdayText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: date).uppercased(with: locale)
    }

    /// 日付。例: `August 31, 2026`
    public func dateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMMdyyyy")
        return formatter.string(from: date)
    }

    /// タイムゾーン行。例: `TOKYO · JST · UTC+09:00`
    ///
    /// 短縮名を持たないタイムゾーンでは中央を落として
    /// `KOLKATA · UTC+05:30` のように 2 要素で出す。
    public func timeZoneText(for date: Date) -> String {
        [cityText, abbreviationText(for: date), utcOffsetText(for: date)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// 識別子の末尾を都市名として使う。例: `Asia/Tokyo` → `TOKYO`
    private var cityText: String {
        let component = timeZone.identifier.split(separator: "/").last.map(String.init)
            ?? timeZone.identifier
        return component.replacingOccurrences(of: "_", with: " ").uppercased(with: locale)
    }

    /// 略称。例: `JST`
    ///
    /// 短縮名が定義されていないタイムゾーンでは `GMT+9` のようなオフセット表記が
    /// 返る。それは 3 つ目の要素と重複するので、その場合は nil を返して落とす。
    private func abbreviationText(for date: Date) -> String? {
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date)
            ? .shortDaylightSaving
            : .shortStandard
        guard let name = timeZone.localizedName(for: style, locale: locale) else { return nil }
        guard !name.hasPrefix("GMT"), !name.hasPrefix("UTC") else { return nil }
        return name
    }

    /// UTC からのオフセット。例: `UTC+09:00`
    private func utcOffsetText(for date: Date) -> String {
        let offset = timeZone.secondsFromGMT(for: date)
        let sign = offset < 0 ? "-" : "+"
        let magnitude = abs(offset)
        return "UTC\(sign)\(Self.twoDigits(magnitude / 3600)):\(Self.twoDigits(magnitude % 3600 / 60))"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
