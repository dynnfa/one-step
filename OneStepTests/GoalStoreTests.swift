import SwiftData
import XCTest
import OneStepCore
@testable import OneStep

@MainActor
final class GoalStoreTests: XCTestCase {
    func testRefreshLoadsGoalsFromRepositoryForRequestedDay() throws {
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fixture = try makeFixture()

        _ = try fixture.repository.createGoal(CreateGoalInput(
            title: "Vocabulary",
            dailyAction: "Study 30 minutes",
            targetCompletionDays: 200,
            startDay: day
        ))

        fixture.store.refresh(day: day)

        XCTAssertEqual(fixture.store.goals.map(\.title), ["Vocabulary"])
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testCreateGoalMarksFirstGoalAndRefreshesList() throws {
        let fixture = try makeFixture()

        fixture.store.createGoal(
            title: "Vocabulary",
            dailyAction: "Study 30 minutes",
            targetCompletionDays: 200
        )

        XCTAssertTrue(fixture.store.didCreateFirstGoal)
        XCTAssertEqual(fixture.store.goals.map(\.dailyAction), ["Study 30 minutes"])
    }

    func testUpdateGoalRefreshesListAndReportsRepositoryErrors() throws {
        let fixture = try makeFixture()
        fixture.store.createGoal(title: "Vocabulary", dailyAction: "Study 30 minutes", targetCompletionDays: 2)
        let goalID = try XCTUnwrap(fixture.store.goals.first?.id)
        fixture.store.completeToday(goalID: goalID)

        fixture.store.updateGoal(
            goalID: goalID,
            title: "Language",
            dailyAction: "Review cards",
            targetCompletionDays: 1
        )
        XCTAssertEqual(fixture.store.goals.first?.title, "Language")
        XCTAssertNil(fixture.store.errorMessage)

        fixture.store.updateGoal(
            goalID: goalID,
            title: "Language",
            dailyAction: "Review cards",
            targetCompletionDays: 0
        )
        XCTAssertEqual(fixture.store.errorMessage, GoalRepositoryError.invalidTargetCompletionDays.localizedDescription)
    }

    func testCompleteUndoArchiveAndMoveRefreshListState() throws {
        let fixture = try makeFixture()
        fixture.store.createGoal(title: "First", dailyAction: "Do first", targetCompletionDays: 10)
        fixture.store.createGoal(title: "Second", dailyAction: "Do second", targetCompletionDays: 10)
        let firstID = try XCTUnwrap(fixture.store.goals.first { $0.title == "First" }?.id)
        let secondID = try XCTUnwrap(fixture.store.goals.first { $0.title == "Second" }?.id)

        fixture.store.completeToday(goalID: firstID)
        XCTAssertTrue(try XCTUnwrap(fixture.store.goals.first { $0.id == firstID }).isCompletedToday)

        fixture.store.uncompleteToday(goalID: firstID)
        XCTAssertFalse(try XCTUnwrap(fixture.store.goals.first { $0.id == firstID }).isCompletedToday)

        fixture.store.move(from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(fixture.store.goals.map(\.id), [secondID, firstID])

        fixture.store.archiveGoal(goalID: secondID)
        XCTAssertNotNil(try XCTUnwrap(fixture.store.goals.first { $0.id == secondID }).archivedAt)
    }

    private func makeFixture() throws -> Fixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let repository = GoalRepository(modelContext: ModelContext(container))
        return Fixture(repository: repository, store: GoalStore(repository: repository))
    }
}

@MainActor
private struct Fixture {
    let repository: GoalRepository
    let store: GoalStore
}
