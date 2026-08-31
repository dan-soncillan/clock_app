import XCTest
@testable import ClockCore

final class CalendarProgressTests: XCTestCase {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private func date(
        year: Int = 2026, month: Int = 8, day: Int = 31,
        hour: Int = 0, minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        return calendar.date(from: DateComponents(
            timeZone: tokyo, year: year, month: month, day: day, hour: hour, minute: minute
        ))!
    }

    func testDesignReferenceMoment() {
        // ハンドオフのスクリーンショットと同じ 2026-08-31 11:25 JST。
        let progress = CalendarProgress(date: date(hour: 11, minute: 25), timeZone: tokyo)
        XCTAssertEqual(progress.year, 2026)
        XCTAssertEqual(progress.remainingMinutesToday, 755)
        XCTAssertEqual(progress.remainingTodayText, "12:35")
        XCTAssertEqual(progress.dayOfYear, 243)
        XCTAssertEqual(progress.daysInYear, 365)
        XCTAssertEqual(progress.daysRemaining, 122)
        XCTAssertEqual(progress.weeksRemaining, 17)
        XCTAssertEqual(progress.weekNumber, 35)
    }

    func testMidnightLeavesTheWholeDay() {
        let progress = CalendarProgress(date: date(month: 1, day: 1), timeZone: tokyo)
        XCTAssertEqual(progress.remainingMinutesToday, 1440)
        XCTAssertEqual(progress.remainingTodayText, "24:00")
        XCTAssertEqual(progress.dayRemainingFraction, 1, accuracy: 0.0001)
        XCTAssertEqual(progress.dayOfYear, 1)
        XCTAssertEqual(progress.weekNumber, 1)
    }

    func testLastMinuteOfTheYear() {
        let progress = CalendarProgress(date: date(month: 12, day: 31, hour: 23, minute: 59), timeZone: tokyo)
        XCTAssertEqual(progress.remainingMinutesToday, 1)
        XCTAssertEqual(progress.remainingTodayText, "00:01")
        XCTAssertEqual(progress.daysRemaining, 0)
        XCTAssertEqual(progress.weeksRemaining, 0)
        XCTAssertEqual(progress.yearRemainingFraction, 0, accuracy: 0.0001)
    }

    func testWeekRemainderCountsDownToMonday() {
        // 2026-08-31 は月曜。11:25 の時点で残りは 6日と 12:35。
        let monday = CalendarProgress(date: date(hour: 11, minute: 25), timeZone: tokyo)
        XCTAssertEqual(monday.remainingMinutesInWeek, 7 * 1440 - 685)
        XCTAssertEqual(monday.remainingWeekText, "6D 12:35")
        XCTAssertEqual(monday.weekRemainingFraction, 0.932, accuracy: 0.001)

        // 日曜 23:59 は週の最後の1分。
        let sundayNight = CalendarProgress(
            date: date(month: 9, day: 6, hour: 23, minute: 59), timeZone: tokyo
        )
        XCTAssertEqual(sundayNight.remainingMinutesInWeek, 1)
        XCTAssertEqual(sundayNight.remainingWeekText, "0D 00:01")

        XCTAssertEqual(monday.weekAxisMilestones, [7, 6, 5, 4, 3, 2, 1, 0])
    }

    func testYearAxisIsQuartered() {
        let progress = CalendarProgress(date: date(hour: 11, minute: 25), timeZone: tokyo)
        XCTAssertEqual(progress.yearAxisMilestones, [365, 274, 183, 91, 0])

        let leap = CalendarProgress(date: date(year: 2028, month: 3, day: 1), timeZone: tokyo)
        XCTAssertEqual(leap.yearAxisMilestones, [366, 275, 183, 92, 0])
    }

    func testLeapYearHas366Days() {
        let progress = CalendarProgress(date: date(year: 2028, month: 3, day: 1), timeZone: tokyo)
        XCTAssertEqual(progress.daysInYear, 366)
        XCTAssertEqual(progress.dayOfYear, 61) // 31 + 29 + 1
    }

    func testFractionsTrackTheRemainder() {
        let progress = CalendarProgress(date: date(hour: 12, minute: 0), timeZone: tokyo)
        XCTAssertEqual(progress.dayRemainingFraction, 0.5, accuracy: 0.0001)
        XCTAssertEqual(
            progress.yearRemainingFraction,
            Double(progress.daysRemaining) / Double(progress.daysInYear),
            accuracy: 0.0001
        )
    }
}
