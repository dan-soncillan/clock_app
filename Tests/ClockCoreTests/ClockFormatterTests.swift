import XCTest
@testable import ClockCore

final class ClockFormatterTests: XCTestCase {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private func date(hour: Int, minute: Int, second: Int, timeZone: TimeZone? = nil) -> Date {
        let zone = timeZone ?? tokyo
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(
            timeZone: zone, year: 2026, month: 8, day: 31,
            hour: hour, minute: minute, second: second
        ))!
    }

    func testTwentyFourHourClockPadsBothFields() {
        let formatter = ClockFormatter(timeZone: tokyo, uses24HourClock: true)
        XCTAssertEqual(formatter.hourMinuteText(for: date(hour: 9, minute: 5, second: 3)), "09:05")
        XCTAssertEqual(formatter.hourMinuteText(for: date(hour: 15, minute: 0, second: 0)), "15:00")
    }

    func testTwelveHourClockKeepsTwoDigits() {
        // 等幅数字の桁数を保つため、12時間表記でも先頭のゼロを落とさない。
        let formatter = ClockFormatter(timeZone: tokyo, uses24HourClock: false)
        XCTAssertEqual(formatter.hourMinuteText(for: date(hour: 15, minute: 0, second: 0)), "03:00")
        XCTAssertEqual(formatter.hourMinuteText(for: date(hour: 0, minute: 30, second: 0)), "12:30")
        XCTAssertEqual(formatter.hourMinuteText(for: date(hour: 12, minute: 30, second: 0)), "12:30")
    }

    func testPeriodOnlyAppearsInTwelveHourClock() {
        let twentyFour = ClockFormatter(timeZone: tokyo, uses24HourClock: true)
        XCTAssertNil(twentyFour.periodText(for: date(hour: 15, minute: 20, second: 0)))

        let twelve = ClockFormatter(timeZone: tokyo, uses24HourClock: false)
        XCTAssertEqual(twelve.periodText(for: date(hour: 15, minute: 20, second: 0)), "PM")
        XCTAssertEqual(twelve.periodText(for: date(hour: 9, minute: 0, second: 0)), "AM")
        XCTAssertEqual(twelve.periodText(for: date(hour: 0, minute: 0, second: 0)), "AM")
        XCTAssertEqual(twelve.periodText(for: date(hour: 12, minute: 0, second: 0)), "PM")
    }

    func testNoonReadsTheSameInBothFormats() {
        // 12時台は両方の表記が同じ文字列になる。AM/PM が無いと区別できない。
        let noon = date(hour: 12, minute: 7, second: 0)
        XCTAssertEqual(ClockFormatter(timeZone: tokyo, uses24HourClock: true).hourMinuteText(for: noon), "12:07")
        XCTAssertEqual(ClockFormatter(timeZone: tokyo, uses24HourClock: false).hourMinuteText(for: noon), "12:07")
    }

    func testSecondIsPadded() {
        let formatter = ClockFormatter(timeZone: tokyo)
        XCTAssertEqual(formatter.secondText(for: date(hour: 11, minute: 25, second: 3)), "03")
        XCTAssertEqual(formatter.secondText(for: date(hour: 11, minute: 25, second: 39)), "39")
    }

    func testWeekdayAndDateFollowTheDesign() {
        let formatter = ClockFormatter(timeZone: tokyo)
        let moment = date(hour: 11, minute: 25, second: 39)
        XCTAssertEqual(formatter.weekdayText(for: moment), "MONDAY")
        XCTAssertEqual(formatter.dateText(for: moment), "August 31, 2026")
    }

    func testTimeZoneLineMatchesTheDesign() {
        // 中央の短縮名（JST など）が使えるかは ICU のデータ次第なので、
        // 都市が先頭・オフセットが末尾という並びと、
        // オフセット表記が重複して入らないことを確認する。
        let formatter = ClockFormatter(timeZone: tokyo)
        let text = formatter.timeZoneText(for: date(hour: 11, minute: 25, second: 39))
        XCTAssertTrue(text.hasPrefix("TOKYO · "), text)
        XCTAssertTrue(text.hasSuffix("UTC+09:00"), text)
        XCTAssertFalse(text.contains("GMT"), text)
    }

    func testTimeZoneLineHandlesHalfHourOffsets() {
        let kolkata = TimeZone(identifier: "Asia/Kolkata")!
        let formatter = ClockFormatter(timeZone: kolkata)
        let text = formatter.timeZoneText(for: date(hour: 11, minute: 25, second: 0, timeZone: kolkata))
        XCTAssertTrue(text.hasPrefix("KOLKATA · "), text)
        XCTAssertTrue(text.hasSuffix(" · UTC+05:30"), text)
        XCTAssertFalse(text.contains("GMT"), text)
    }

    func testTimeZoneLineHandlesNegativeOffsets() {
        let newYork = TimeZone(identifier: "America/New_York")!
        let formatter = ClockFormatter(timeZone: newYork)
        let text = formatter.timeZoneText(for: date(hour: 11, minute: 25, second: 0, timeZone: newYork))
        XCTAssertTrue(text.hasPrefix("NEW YORK · "), text)
        XCTAssertTrue(text.hasSuffix(" · UTC-04:00"), text) // 8月は夏時間
    }
}
