import XCTest
@testable import OneStepCore

final class DomainTypeTests: XCTestCase {
    func testGoalTracksActiveArchiveState() {
        let goal = Goal(
            title: "Write",
            dailyAction: "Write one paragraph",
            targetCompletionDays: 30,
            startDayKey: "2026-04-29",
            sortOrder: 0
        )

        XCTAssertTrue(goal.isActive)

        goal.archivedAt = Date()

        XCTAssertFalse(goal.isActive)
    }

    func testDailyCompletionUniqueKeyUsesGoalAndDay() {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let completion = DailyCompletion(goalID: goalID, dayKey: "2026-04-29")

        XCTAssertEqual(completion.uniqueKey, "00000000-0000-0000-0000-000000000001#2026-04-29")
        XCTAssertEqual(
            DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: "2026-04-29"),
            completion.uniqueKey
        )
    }

    func testSnapshotsPreserveInputValues() throws {
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let createInput = CreateGoalInput(
            title: "Write",
            dailyAction: "Write one paragraph",
            targetCompletionDays: 30,
            startDay: startDay
        )
        let updateInput = UpdateGoalInput(
            title: "Read",
            dailyAction: "Read five pages",
            targetCompletionDays: 10
        )
        let recentActivity = RecentActivityDay(day: startDay, isCompleted: true)
        let snapshot = GoalListSnapshot(
            id: UUID(),
            title: createInput.title,
            dailyAction: createInput.dailyAction,
            targetCompletionDays: createInput.targetCompletionDays,
            completedDays: 1,
            remainingDays: 29,
            completionRate: 1.0 / 30.0,
            isCompletedToday: true,
            sortOrder: 0,
            archivedAt: nil,
            recentActivity: [recentActivity]
        )

        XCTAssertEqual(createInput.startDay, startDay)
        XCTAssertEqual(updateInput.dailyAction, "Read five pages")
        XCTAssertEqual(recentActivity.id, "2026-04-29")
        XCTAssertEqual(snapshot.recentActivity, [recentActivity])
    }

    func testRepositoryErrorsExposeDescriptions() {
        XCTAssertEqual(GoalRepositoryError.goalNotFound.errorDescription, "Goal not found.")
        XCTAssertEqual(GoalRepositoryError.saveFailed("disk").errorDescription, "Save failed: disk")
    }
}
