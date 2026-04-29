import SwiftData
import XCTest
@testable import OneStepCore

@MainActor
final class GoalRepositoryTests: XCTestCase {
    func testModelContainerFactoryBuildsExpectedSharedStoreURL() {
        let baseURL = URL(fileURLWithPath: "/tmp/app-group", isDirectory: true)

        let storeURL = OneStepModelContainerFactory.storeURL(appGroupContainerURL: baseURL)

        XCTAssertEqual(storeURL.path, "/tmp/app-group/OneStep/OneStep.sqlite")
    }

    func testCreateGoalAcceptsValidDataAndTrimsStrings() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let id = try fixture.repository.createGoal(CreateGoalInput(
            title: "  Write  ",
            dailyAction: "  Write one paragraph  ",
            targetCompletionDays: 30,
            startDay: startDay
        ))
        let snapshots = try fixture.repository.goalsForList(day: startDay)

        XCTAssertEqual(snapshots.map(\.id), [id])
        XCTAssertEqual(snapshots.first?.title, "Write")
        XCTAssertEqual(snapshots.first?.dailyAction, "Write one paragraph")
        XCTAssertEqual(snapshots.first?.targetCompletionDays, 30)
        XCTAssertEqual(snapshots.first?.sortOrder, 0)
    }

    func testCreateGoalRejectsEmptyTitle() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.createGoal(CreateGoalInput(
            title: "   ",
            dailyAction: "Write one paragraph",
            targetCompletionDays: 30,
            startDay: startDay
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidTitle)
        }
    }

    func testCreateGoalRejectsEmptyDailyAction() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.createGoal(CreateGoalInput(
            title: "Write",
            dailyAction: "   ",
            targetCompletionDays: 30,
            startDay: startDay
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidDailyAction)
        }
    }

    func testCreateGoalRejectsTargetCompletionDaysLessThanOne() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.createGoal(CreateGoalInput(
            title: "Write",
            dailyAction: "Write one paragraph",
            targetCompletionDays: 0,
            startDay: startDay
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidTargetCompletionDays)
        }
    }

    func testCompleteTodayInsertsOneCompletion() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Write", day: day)

        try fixture.repository.completeToday(goalID: goalID, day: day)

        XCTAssertEqual(try fixture.fetchCompletions().map(\.dayKey), ["2026-04-29"])
        XCTAssertEqual(try fixture.repository.goalsForList(day: day).first?.completedDays, 1)
        XCTAssertEqual(try fixture.repository.goalsForList(day: day).first?.isCompletedToday, true)
    }

    func testCompleteTodayIsIdempotentForSameGoalAndDay() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Write", day: day)

        try fixture.repository.completeToday(goalID: goalID, day: day)
        try fixture.repository.completeToday(goalID: goalID, day: day)

        XCTAssertEqual(try fixture.fetchCompletions().count, 1)
    }

    func testCompleteTodayThrowsGoalNotFoundForMissingID() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.completeToday(goalID: UUID(), day: day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .goalNotFound)
        }
    }

    func testCompleteTodayThrowsGoalNotActiveForArchivedGoal() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Write", day: day)

        try fixture.repository.archiveGoal(goalID: goalID, archivedAt: Date())

        XCTAssertThrowsError(try fixture.repository.completeToday(goalID: goalID, day: day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .goalNotActive)
        }
    }

    func testUncompleteTodayRemovesOnlyTodaysRecord() throws {
        let fixture = try makeFixture()
        let today = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let yesterday = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))
        let goalID = try fixture.createGoal(title: "Write", day: yesterday)

        try fixture.repository.completeToday(goalID: goalID, day: yesterday)
        try fixture.repository.completeToday(goalID: goalID, day: today)
        try fixture.repository.uncompleteToday(goalID: goalID, day: today)

        XCTAssertEqual(try fixture.fetchCompletions().map(\.dayKey), ["2026-04-28"])
    }

    func testUpdateGoalRejectsTargetBelowCompletedCount() throws {
        let fixture = try makeFixture()
        let firstDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))
        let secondDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Write", day: firstDay, targetCompletionDays: 10)

        try fixture.repository.completeToday(goalID: goalID, day: firstDay)
        try fixture.repository.completeToday(goalID: goalID, day: secondDay)

        XCTAssertThrowsError(try fixture.repository.updateGoal(
            goalID: goalID,
            input: UpdateGoalInput(title: "Write", dailyAction: "Write one page", targetCompletionDays: 1)
        )) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .targetBelowCompletedCount)
        }
    }

    func testUpdateGoalAppliesTrimmedValues() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Write", day: day, targetCompletionDays: 10)

        try fixture.repository.updateGoal(
            goalID: goalID,
            input: UpdateGoalInput(title: "  Read  ", dailyAction: "  Read five pages  ", targetCompletionDays: 20)
        )

        let snapshot = try XCTUnwrap(try fixture.repository.goalsForList(day: day).first { $0.id == goalID })
        XCTAssertEqual(snapshot.title, "Read")
        XCTAssertEqual(snapshot.dailyAction, "Read five pages")
        XCTAssertEqual(snapshot.targetCompletionDays, 20)
    }

    func testMoveActiveGoalChangesActiveWidgetOrder() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let first = try fixture.createGoal(title: "First", day: day)
        let archived = try fixture.createGoal(title: "Archived", day: day)
        let third = try fixture.createGoal(title: "Third", day: day)
        try fixture.repository.archiveGoal(goalID: archived, archivedAt: Date())

        try fixture.repository.moveActiveGoal(goalID: third, toIndex: 0)

        let widgetIDs = try fixture.repository.activeGoalsForWidget(limit: 10, day: day).map(\.id)
        XCTAssertEqual(widgetIDs, [third, first])
        XCTAssertEqual(try fixture.repository.goalsForList(day: day).map(\.id), [third, first, archived])
    }

    func testActiveGoalsForWidgetExcludesArchivedGoalsAndRespectsLimit() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let first = try fixture.createGoal(title: "First", day: day)
        let archived = try fixture.createGoal(title: "Archived", day: day)
        let third = try fixture.createGoal(title: "Third", day: day)
        try fixture.repository.archiveGoal(goalID: archived, archivedAt: Date())
        try fixture.repository.completeToday(goalID: first, day: day)

        let snapshots = try fixture.repository.activeGoalsForWidget(limit: 1, day: day)

        XCTAssertEqual(snapshots.map(\.id), [first])
        XCTAssertEqual(snapshots.first?.completedDays, 1)
        XCTAssertEqual(snapshots.first?.isCompletedToday, true)
        XCTAssertFalse(snapshots.contains { $0.id == archived || $0.id == third })
    }

    func testActiveGoalsForWidgetTreatsNegativeLimitAsEmpty() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        _ = try fixture.createGoal(title: "Write", day: day)

        XCTAssertEqual(try fixture.repository.activeGoalsForWidget(limit: -1, day: day), [])
    }

    func testGoalsForListIncludesThirtyRecentActivityDaysEndingOnRequestedDay() throws {
        let fixture = try makeFixture()
        let requestedDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let completedDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))
        let goalID = try fixture.createGoal(title: "Write", day: requestedDay)

        try fixture.repository.completeToday(goalID: goalID, day: completedDay)

        let activity = try XCTUnwrap(try fixture.repository.goalsForList(day: requestedDay).first?.recentActivity)
        XCTAssertEqual(activity.count, 30)
        XCTAssertEqual(activity.first?.day.rawValue, "2026-03-31")
        XCTAssertEqual(activity.last?.day.rawValue, "2026-04-29")
        XCTAssertEqual(activity.first { $0.day == completedDay }?.isCompleted, true)
    }

    private func makeFixture() throws -> GoalRepositoryFixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        return GoalRepositoryFixture(modelContext: context, repository: GoalRepository(modelContext: context))
    }
}

@MainActor
private struct GoalRepositoryFixture {
    let modelContext: ModelContext
    let repository: GoalRepository

    func createGoal(title: String, day: LocalDay, targetCompletionDays: Int = 30) throws -> UUID {
        try repository.createGoal(CreateGoalInput(
            title: title,
            dailyAction: "\(title) action",
            targetCompletionDays: targetCompletionDays,
            startDay: day
        ))
    }

    func fetchCompletions() throws -> [DailyCompletion] {
        let descriptor = FetchDescriptor<DailyCompletion>(
            sortBy: [SortDescriptor(\DailyCompletion.dayKey)]
        )
        return try modelContext.fetch(descriptor)
    }
}
