import SwiftData
import XCTest
@testable import OneStepCore

@MainActor
final class GoalRepositoryCompletionTests: XCTestCase {
    func testCompleteTodayThrowsGoalNotFoundForMissingGoalWithoutCreatingCompletion() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.completeToday(goalID: UUID(), day: day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .goalNotFound)
        }
        XCTAssertEqual(try fixture.fetchCompletions(), [])
    }

    func testCompleteTodayThrowsGoalNotActiveForArchivedGoalWithoutCreatingCompletion() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let goalID = try fixture.createGoal(title: "Vocabulary", day: day)

        try fixture.repository.archiveGoal(goalID: goalID, archivedAt: Date())

        XCTAssertThrowsError(try fixture.repository.completeToday(goalID: goalID, day: day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .goalNotActive)
        }
        XCTAssertEqual(try fixture.fetchCompletions(), [])
    }

    private func makeFixture() throws -> GoalRepositoryCompletionFixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        return GoalRepositoryCompletionFixture(modelContext: context, repository: GoalRepository(modelContext: context))
    }
}

@MainActor
private struct GoalRepositoryCompletionFixture {
    let modelContext: ModelContext
    let repository: GoalRepository

    func createGoal(title: String, day: LocalDay) throws -> UUID {
        try repository.createGoal(CreateGoalInput(
            title: title,
            dailyAction: "\(title) action",
            targetCompletionDays: 30,
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
