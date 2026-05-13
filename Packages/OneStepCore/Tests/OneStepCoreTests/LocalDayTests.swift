import XCTest
@testable import OneStepCore

final class LocalDayTests: XCTestCase {
    func testLocalDayUsesCalendarYearMonthDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let date = ISO8601DateFormatter().date(from: "2026-04-29T15:59:59Z")!
        XCTAssertEqual(LocalDay(date: date, calendar: calendar).rawValue, "2026-04-29")
    }

    func testSameInstantCanProduceDifferentLocalDays() {
        let instant = ISO8601DateFormatter().date(from: "2026-04-29T00:30:00Z")!
        var shanghai = Calendar(identifier: .gregorian)
        shanghai.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(secondsFromGMT: -7 * 3600)!
        XCTAssertEqual(LocalDay(date: instant, calendar: shanghai).rawValue, "2026-04-29")
        XCTAssertEqual(LocalDay(date: instant, calendar: losAngeles).rawValue, "2026-04-28")
    }

    func testRawValueInitializerAcceptsValidKey() throws {
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        XCTAssertEqual(day.rawValue, "2026-04-29")
    }

    func testRawValueInitializerRejectsInvalidKey() {
        XCTAssertNil(LocalDay(rawValue: "2026-4-9"))
        XCTAssertNil(LocalDay(rawValue: "not-a-day"))
    }

    func testDaysUntilCountsCalendarDays() throws {
        let start = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let nextDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-30"))
        let previousDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))

        XCTAssertEqual(start.days(until: nextDay), 1)
        XCTAssertEqual(start.days(until: start), 0)
        XCTAssertEqual(start.days(until: previousDay), -1)
    }

    func testDaysUntilUsesLocalDayKeysRatherThanCurrentInstant() throws {
        let shanghaiDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let losAngelesDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))

        XCTAssertEqual(losAngelesDay.days(until: shanghaiDay), 1)
    }
}
