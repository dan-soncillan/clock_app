import XCTest
@testable import ClockCore

final class ClockHandsTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    private func date(h: Int, m: Int, s: Int, nanosecond: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(
            timeZone: utc, year: 2026, month: 8, day: 31,
            hour: h, minute: m, second: s, nanosecond: nanosecond
        ))!
    }

    func testMidnightPutsEveryHandAtTop() {
        let hands = ClockHands(date: date(h: 0, m: 0, s: 0), timeZone: utc)
        XCTAssertEqual(hands.hour, 0, accuracy: 0.001)
        XCTAssertEqual(hands.minute, 0, accuracy: 0.001)
        XCTAssertEqual(hands.second, 0, accuracy: 0.001)
    }

    func testHourHandAdvancesWithMinutes() {
        // 3:30 なら短針は 3 と 4 のちょうど中間（105 度）。
        let hands = ClockHands(date: date(h: 3, m: 30, s: 0), timeZone: utc)
        XCTAssertEqual(hands.hour, 105, accuracy: 0.001)
        XCTAssertEqual(hands.minute, 180, accuracy: 0.001)
    }

    func testAfternoonWrapsToTwelveHourDial() {
        let hands = ClockHands(date: date(h: 15, m: 0, s: 0), timeZone: utc)
        XCTAssertEqual(hands.hour, 90, accuracy: 0.001)
    }

    func testMinuteHandAdvancesWithSeconds() {
        let hands = ClockHands(date: date(h: 0, m: 0, s: 30), timeZone: utc)
        XCTAssertEqual(hands.minute, 3, accuracy: 0.001)
        XCTAssertEqual(hands.second, 180, accuracy: 0.001)
    }

    func testSweepingSecondsUseSubSecondPrecision() {
        let moment = date(h: 0, m: 0, s: 10, nanosecond: 500_000_000)
        let sweeping = ClockHands(date: moment, timeZone: utc, sweepingSeconds: true)
        let ticking = ClockHands(date: moment, timeZone: utc, sweepingSeconds: false)
        XCTAssertEqual(sweeping.second, 63, accuracy: 0.1)
        XCTAssertEqual(ticking.second, 60, accuracy: 0.001)
    }

    func testTimeZoneChangesTheDial() {
        let moment = date(h: 0, m: 0, s: 0)
        let tokyo = ClockHands(date: moment, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        XCTAssertEqual(tokyo.hour, 270, accuracy: 0.001) // UTC 0:00 = 東京 9:00
    }
}
