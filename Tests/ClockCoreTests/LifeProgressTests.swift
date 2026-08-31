import XCTest
@testable import ClockCore

final class LifeProgressTests: XCTestCase {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let birthday = DateComponents(year: 1990, month: 6, day: 15)

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
        XCTAssertEqual(result.age, 36)
        XCTAssertEqual(result.yearsRemaining, 44)
        XCTAssertEqual(result.daysRemaining, 15_993)
        XCTAssertEqual(result.remainingFraction, 0.5473, accuracy: 0.001)
    }

    func testAgeTicksOverOnTheBirthday() {
        let before = progress(at: date(2027, 6, 14))
        let onTheDay = progress(at: date(2027, 6, 15))
        XCTAssertEqual(before.age, 36)
        XCTAssertEqual(before.yearsRemaining, 44)
        XCTAssertEqual(onTheDay.age, 37)
        XCTAssertEqual(onTheDay.yearsRemaining, 43)
    }

    func testEverythingIsZeroAtTheTargetAge() {
        let result = progress(at: date(2070, 6, 15))
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
        let result = progress(at: date(1990, 6, 15, hour: 0))
        XCTAssertEqual(result.age, 0)
        XCTAssertEqual(result.yearsRemaining, 80)
        XCTAssertEqual(result.remainingFraction, 1, accuracy: 0.0001)
    }

    func testCompactText() {
        XCTAssertEqual(progress(at: date(2026, 8, 31)).remainingText, "44Y | 15,993D")
    }

    func testAxisIsQuartered() {
        XCTAssertEqual(progress(at: date(2026, 8, 31)).axisMilestones, [80, 60, 40, 20, 0])
    }
}
