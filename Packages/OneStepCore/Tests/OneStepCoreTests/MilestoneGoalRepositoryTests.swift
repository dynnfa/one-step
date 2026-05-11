import SwiftData
import XCTest
@testable import OneStepCore

@MainActor
final class MilestoneGoalRepositoryTests: XCTestCase {
    // MARK: - Create

    func testCreateMilestoneAppendsSortOrder() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: "Phase 1", targetCompletionDays: 5, finalGoalID: fgID
        ))
        let m2 = try fixture.repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: "Phase 2", targetCompletionDays: 10, finalGoalID: fgID
        ))

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.map(\.id), [m1, m2])
        XCTAssertEqual(milestones.map(\.sortOrder), [0, 1])
    }

    func testCreateMilestoneRejectsMissingFinalGoal() throws {
        let fixture = try makeFixture()

        XCTAssertThrowsError(try fixture.repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: "Orphan", targetCompletionDays: 5, finalGoalID: UUID()
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .finalGoalNotFound)
        }
    }

    func testCreateMilestoneRejectsInvalidTarget() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()

        XCTAssertThrowsError(try fixture.repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: "Bad", targetCompletionDays: 0, finalGoalID: fgID
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidTargetCompletionDays)
        }
    }

    func testCreateMilestoneRejectsArchivedFinalGoal() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let finalGoalRepository = FinalGoalRepository(modelContext: fixture.modelContext)
        try finalGoalRepository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        XCTAssertThrowsError(try fixture.repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: "Phase 1", targetCompletionDays: 5, finalGoalID: fgID
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .finalGoalNotActive)
        }
    }

    func testNewMilestonesStartInactive() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)

        XCTAssertEqual(milestones.map(\.isActive), [false, false])
    }

    // MARK: - Check-in

    func testCompleteTodayRejectsInactiveMilestone() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        let m2 = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)

        XCTAssertThrowsError(try fixture.repository.completeToday(milestoneGoalID: m2, day: fixture.day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .milestoneNotActive)
        }
    }

    func testCompleteTodayAllowsActiveMilestone() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones[0].completedDays, 1)
        XCTAssertEqual(milestones[0].isCompletedToday, true)
    }

    func testCompleteTodayDoesNotAutoAdvanceToNextMilestone() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertNotNil(milestones[0].completedAt)
        XCTAssertEqual(milestones[1].isActive, false)
    }

    func testCompleteTodaySetsStartDayKeyOnFirstOnly() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 3, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.startDayKey, fixture.day.rawValue)
    }

    func testCompleteTodayIsIdempotentPerDay() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)
        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.completedDays, 1)
    }

    func testAutoCompletesAtTarget() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 2, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        let day1 = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))
        let day2 = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        try fixture.repository.completeToday(milestoneGoalID: m1, day: day1)
        try fixture.repository.completeToday(milestoneGoalID: m1, day: day2)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertNotNil(milestones[0].completedAt)
        XCTAssertEqual(milestones[1].isActive, false)
    }

    func testUpdateMilestoneCompletesWhenTargetDropsToCompletedDays() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let milestoneID = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: milestoneID, isActive: true)
        let day1 = try XCTUnwrap(LocalDay(rawValue: "2026-04-27"))
        let day2 = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))
        let day3 = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        try fixture.repository.completeToday(milestoneGoalID: milestoneID, day: day1)
        try fixture.repository.completeToday(milestoneGoalID: milestoneID, day: day2)
        try fixture.repository.completeToday(milestoneGoalID: milestoneID, day: day3)

        try fixture.repository.updateMilestoneGoal(
            milestoneGoalID: milestoneID,
            input: UpdateMilestoneGoalInput(title: "Phase 1", targetCompletionDays: 3)
        )

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.completedDays, 3)
        XCTAssertNotNil(milestones.first?.completedAt)
        XCTAssertEqual(milestones.first?.isActive, false)
    }

    // MARK: - Undo

    func testUncompleteTodayRemovesCompletion() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)
        try fixture.repository.uncompleteToday(milestoneGoalID: m1, day: fixture.day)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.completedDays, 0)
        XCTAssertEqual(milestones.first?.isCompletedToday, false)
    }

    func testUncompleteTodayRejectsArchivedFinalGoal() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)
        let finalGoalRepository = FinalGoalRepository(modelContext: fixture.modelContext)
        try finalGoalRepository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        XCTAssertThrowsError(try fixture.repository.uncompleteToday(milestoneGoalID: m1, day: fixture.day)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .finalGoalNotActive)
        }

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.completedDays, 1)
        XCTAssertEqual(milestones.first?.isCompletedToday, true)
    }

    func testUncompleteReopensCompletedMilestone() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)
        let afterComplete = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertNotNil(afterComplete[0].completedAt)

        try fixture.repository.uncompleteToday(milestoneGoalID: m1, day: fixture.day)
        let afterUndo = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertNil(afterUndo[0].completedAt)
    }

    // MARK: - Delete

    func testDeleteMilestoneCascadesCompletions() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)
        XCTAssertEqual(try fixture.fetchAllCompletions().count, 1)

        try fixture.repository.deleteMilestoneGoal(milestoneGoalID: m1)
        XCTAssertEqual(try fixture.fetchAllCompletions().count, 0)
    }

    // MARK: - Widget

    func testActiveMilestonesForWidgetReturnsActiveMilestonesForEachFinalGoalInOrder() throws {
        let fixture = try makeFixture()
        let fg1 = try fixture.createFinalGoal()
        let fg2 = try fixture.createFinalGoal()
        let a1 = try fixture.createMilestone(title: "A1", targetDays: 5, finalGoalID: fg1)
        _ = try fixture.createMilestone(title: "A2", targetDays: 5, finalGoalID: fg1)
        let b1 = try fixture.createMilestone(title: "B1", targetDays: 5, finalGoalID: fg2)
        try fixture.repository.setMilestoneActive(milestoneGoalID: a1, isActive: true)
        try fixture.repository.setMilestoneActive(milestoneGoalID: b1, isActive: true)

        let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 10, day: fixture.day)

        XCTAssertEqual(snapshots.map(\.title), ["A1", "B1"])
    }

    func testActiveMilestonesForWidgetRespectsLimitAcrossActiveMilestones() throws {
        let fixture = try makeFixture()
        let fg1 = try fixture.createFinalGoal()
        let fg2 = try fixture.createFinalGoal()
        let a1 = try fixture.createMilestone(title: "A1", targetDays: 5, finalGoalID: fg1)
        _ = try fixture.createMilestone(title: "A2", targetDays: 5, finalGoalID: fg1)
        let b1 = try fixture.createMilestone(title: "B1", targetDays: 5, finalGoalID: fg2)
        try fixture.repository.setMilestoneActive(milestoneGoalID: a1, isActive: true)
        try fixture.repository.setMilestoneActive(milestoneGoalID: b1, isActive: true)

        let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 2, day: fixture.day)

        XCTAssertEqual(snapshots.map(\.title), ["A1", "B1"])
    }

    func testActiveMilestonesForWidgetExcludesArchivedFinalGoals() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        let fgRepo = FinalGoalRepository(modelContext: fixture.modelContext)
        try fgRepo.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 10, day: fixture.day)
        XCTAssertEqual(snapshots.count, 0)
    }

    func testActiveMilestonesForWidgetSkipsCompletedMilestones() throws {
        let fixture = try makeFixture()
        let goal = try fixture.createFinalGoal()
        let completed = try fixture.createMilestone(title: "Completed", targetDays: 1, finalGoalID: goal)
        let current = try fixture.createMilestone(title: "Current", targetDays: 5, finalGoalID: goal)
        try fixture.repository.setMilestoneActive(milestoneGoalID: completed, isActive: true)
        try fixture.repository.setMilestoneActive(milestoneGoalID: current, isActive: true)

        try fixture.repository.completeToday(milestoneGoalID: completed, day: fixture.day)

        let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 10, day: fixture.day)

        XCTAssertEqual(snapshots.map(\.title), ["Current"])
    }

    func testActiveMilestonesForWidgetIncludesReactivatedFinalGoals() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)

        let fgRepo = FinalGoalRepository(modelContext: fixture.modelContext)
        try fgRepo.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)
        try fgRepo.setFinalGoalArchived(finalGoalID: fgID, isArchived: false)

        let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 10, day: fixture.day)
        XCTAssertEqual(snapshots.map(\.title), ["Phase 1"])
    }

    // MARK: - Recent Activity

    func testSetMilestoneActiveRejectsCompletedMilestone() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)
        try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

        XCTAssertThrowsError(try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .milestoneNotActive)
        }
    }

    func testSetMilestoneActiveRejectsArchivedFinalGoal() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        let fgRepo = FinalGoalRepository(modelContext: fixture.modelContext)
        try fgRepo.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        XCTAssertThrowsError(try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .finalGoalNotActive)
        }
    }

    func testSetMilestoneInactiveSucceedsRegardless() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        let fgRepo = FinalGoalRepository(modelContext: fixture.modelContext)
        try fgRepo.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: false)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(milestones.first?.isActive, false)
    }

    // MARK: - Recent Activity

    func testMilestonesIncludeThirtyRecentActivityDays() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 60, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)
        let completedDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-28"))

        try fixture.repository.completeToday(milestoneGoalID: m1, day: completedDay)

        let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
        let activity = try XCTUnwrap(milestones.first?.recentActivity)
        XCTAssertEqual(activity.count, 30)
        XCTAssertEqual(activity.first { $0.day == completedDay }?.isCompleted, true)
    }

    func testMilestonesUseRequestedRecentActivityDayLimit() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 60, finalGoalID: fgID)
        try fixture.repository.setMilestoneActive(milestoneGoalID: m1, isActive: true)
        let completedDay = try XCTUnwrap(LocalDay(rawValue: "2026-03-20"))

        try fixture.repository.completeToday(milestoneGoalID: m1, day: completedDay)

        let milestones = try fixture.repository.milestonesForFinalGoal(
            finalGoalID: fgID,
            day: fixture.day,
            recentActivityDayLimit: 45
        )
        let activity = try XCTUnwrap(milestones.first?.recentActivity)
        XCTAssertEqual(activity.count, 45)
        XCTAssertEqual(activity.first { $0.day == completedDay }?.isCompleted, true)
    }

    func testRecentActivityDayLimitIsCappedByMilestoneTargetDays() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 7, finalGoalID: fgID)

        let milestones = try fixture.repository.milestonesForFinalGoal(
            finalGoalID: fgID,
            day: fixture.day,
            recentActivityDayLimit: 30
        )

        XCTAssertEqual(milestones.first?.recentActivity.count, 7)
    }

    func testFetchCompletionsCanBeLimitedToDayRange() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let milestoneID = try fixture.createMilestone(title: "Phase 1", targetDays: 90, finalGoalID: fgID)
        let otherMilestoneID = try fixture.createMilestone(title: "Phase 2", targetDays: 90, finalGoalID: fgID)

        fixture.modelContext.insert(DailyCompletion(goalID: milestoneID, dayKey: "2026-03-01"))
        fixture.modelContext.insert(DailyCompletion(goalID: milestoneID, dayKey: "2026-03-20"))
        fixture.modelContext.insert(DailyCompletion(goalID: milestoneID, dayKey: "2026-04-29"))
        fixture.modelContext.insert(DailyCompletion(goalID: otherMilestoneID, dayKey: "2026-03-20"))
        try fixture.modelContext.save()

        let completions = try fixture.repository.fetchCompletions(
            goalID: milestoneID,
            fromDayKey: "2026-03-20",
            throughDayKey: "2026-04-29"
        )

        XCTAssertEqual(completions.map(\.dayKey), ["2026-03-20", "2026-04-29"])
    }

    // MARK: - Helpers

    private func makeFixture() throws -> MilestoneGoalRepositoryFixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        return MilestoneGoalRepositoryFixture(
            modelContext: context,
            repository: MilestoneGoalRepository(modelContext: context),
            day: try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        )
    }
}

@MainActor
private struct MilestoneGoalRepositoryFixture {
    let modelContext: ModelContext
    let repository: MilestoneGoalRepository
    let day: LocalDay

    func createFinalGoal() throws -> UUID {
        let repo = FinalGoalRepository(modelContext: modelContext)
        return try repo.createFinalGoal(CreateFinalGoalInput(title: "Test Goal", startDay: day))
    }

    func createMilestone(title: String, targetDays: Int, finalGoalID: UUID) throws -> UUID {
        try repository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: title, targetCompletionDays: targetDays, finalGoalID: finalGoalID
        ))
    }

    func fetchMilestones(for finalGoalID: UUID) throws -> [MilestoneGoal] {
        let descriptor = FetchDescriptor<MilestoneGoal>(
            predicate: #Predicate { $0.finalGoalID == finalGoalID },
            sortBy: [SortDescriptor(\MilestoneGoal.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllCompletions() throws -> [DailyCompletion] {
        try modelContext.fetch(FetchDescriptor<DailyCompletion>())
    }
}
