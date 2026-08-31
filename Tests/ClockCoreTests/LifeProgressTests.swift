import XCTest
@testable import ClockCore

final class LifeProgressTests: XCTestCase {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let birthday = DateComponents(year: 1993, month: 3, day: 14)

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 15) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        return calendar.date(from: DateComponents(
            timeZone: tokyo, year: year, month: month, day: day, hour: hour
        ))!
    }

    private func progress(at date: Date) -> LifeProgress {
        LifeProgress(date: date, birthday: birthday, targetAge: 80, timeZone: tokyo)
    }

    func testAgeAndRemainderAtAKnownMoment() {
        let result = progress(at: date(2026, 8, 31))
        XCTAssertEqual(result.age, 33)
        XCTAssertEqual(result.yearsRemaining, 47)
        XCTAssertEqual(result.daysRemaining, 16_996)
        XCTAssertEqual(result.remainingFraction, 0.5817, accuracy: 0.001)
    }

    func testAgeTicksOverOnTheBirthday() {
        let before = progress(at: date(2027, 3, 13))
        let onTheDay = progress(at: date(2027, 3, 14))
        XCTAssertEqual(before.age, 33)
        XCTAssertEqual(before.yearsRemaining, 47)
        XCTAssertEqual(onTheDay.age, 34)
        XCTAssertEqual(onTheDay.yearsRemaining, 46)
    }

    func testEverythingIsZeroAtTheTargetAge() {
        let result = progress(at: date(2073, 3, 14))
        XCTAssertEqual(result.yearsRemaining, 0)
        XCTAssertEqual(result.daysRemaining, 0)
        XCTAssertEqual(result.remainingFraction, 0, accuracy: 0.0001)
    }

    func testNothingGoesNegativePastTheTargetAge() {
        let result = progress(at: date(2080, 1, 1))
        XCTAssertEqual(result.yearsRemaining, 0)
        XCTAssertEqual(result.daysRemaining, 0)
        XCTAssertEqual(result.remainingFraction, 0, accuracy: 0.0001)
    }

    func testTheWholeSpanRemainsAtBirth() {
        let result = progress(at: date(1993, 3, 14, hour: 0))
        XCTAssertEqual(result.age, 0)
        XCTAssertEqual(result.yearsRemaining, 80)
        XCTAssertEqual(result.remainingFraction, 1, accuracy: 0.0001)
    }

    func testAxisIsQuartered() {
        XCTAssertEqual(progress(at: date(2026, 8, 31)).axisMilestones, [80, 60, 40, 20, 0])
    }
}
