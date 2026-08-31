import XCTest
@testable import ClockCore

final class ClockFormatterTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    private func date(h: Int, m: Int, s: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(
            timeZone: utc, year: 2026, month: 8, day: 31, hour: h, minute: m, second: s
        ))!
    }

    func testTwentyFourHourClockPadsAndOmitsPeriod() {
        let formatter = ClockFormatter(timeZone: utc, uses24HourClock: true)
        let time = formatter.digitalTime(for: date(h: 9, m: 5, s: 3))
        XCTAssertEqual(time.hour, "09")
        XCTAssertEqual(time.minute, "05")
        XCTAssertEqual(time.second, "03")
        XCTAssertNil(time.period)
    }

    func testTwelveHourClockAddsPeriod() {
        let formatter = ClockFormatter(timeZone: utc, uses24HourClock: false)
        let afternoon = formatter.digitalTime(for: date(h: 15, m: 0, s: 0))
        XCTAssertEqual(afternoon.hour, "03")
        XCTAssertEqual(afternoon.period, "PM")

        let morning = formatter.digitalTime(for: date(h: 9, m: 0, s: 0))
        XCTAssertEqual(morning.period, "AM")
    }

    func testMidnightAndNoonUseTwelveInTwelveHourClock() {
        let formatter = ClockFormatter(timeZone: utc, uses24HourClock: false)
        XCTAssertEqual(formatter.digitalTime(for: date(h: 0, m: 0, s: 0)).hour, "12")
        XCTAssertEqual(formatter.digitalTime(for: date(h: 0, m: 0, s: 0)).period, "AM")
        XCTAssertEqual(formatter.digitalTime(for: date(h: 12, m: 0, s: 0)).hour, "12")
        XCTAssertEqual(formatter.digitalTime(for: date(h: 12, m: 0, s: 0)).period, "PM")
    }

    func testDateTextFollowsLocale() {
        let formatter = ClockFormatter(
            timeZone: utc,
            locale: Locale(identifier: "en_US"),
            uses24HourClock: true
        )
        let text = formatter.dateText(for: date(h: 12, m: 0, s: 0))
        XCTAssertTrue(text.contains("2026"))
        XCTAssertTrue(text.contains("August"))
        XCTAssertTrue(text.contains("Monday"))
    }
}
