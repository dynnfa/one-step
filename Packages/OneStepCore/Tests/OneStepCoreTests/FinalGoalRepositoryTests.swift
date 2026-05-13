import SwiftData
import XCTest
@testable import OneStepCore

@MainActor
final class FinalGoalRepositoryTests: XCTestCase {
    // MARK: - Create

    func testCreateFinalGoalAcceptsValidDataAndTrimsTitle() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let id = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "  Pass IELTS  ",
            goalDescription: "Score 7.0+",
            targetCalendarDays: 180,
            startDay: startDay
        ))
        let snapshots = try fixture.repository.finalGoalsForList()

        XCTAssertEqual(snapshots.count, 1)
        let snapshot = try XCTUnwrap(snapshots.first)
        XCTAssertEqual(snapshot.id, id)
        XCTAssertEqual(snapshot.title, "Pass IELTS")
        XCTAssertEqual(snapshot.goalDescription, "Score 7.0+")
        XCTAssertEqual(snapshot.targetCalendarDays, 180)
        XCTAssertEqual(snapshot.colorThemeID, FinalGoalColorTheme.defaultTheme.id)
        XCTAssertNil(snapshot.customColorHex)
        XCTAssertEqual(snapshot.colorHex, FinalGoalColorTheme.defaultTheme.hex)
        XCTAssertEqual(snapshot.completedMilestoneCount, 0)
        XCTAssertEqual(snapshot.totalMilestoneCount, 0)
        XCTAssertEqual(snapshot.activeMilestoneCount, 0)
        XCTAssertNotNil(snapshot.remainingCalendarDays)
        XCTAssertEqual(snapshot.sortOrder, 0)
    }

    func testCreateFinalGoalRejectsEmptyTitle() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "   ",
            startDay: startDay
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidTitle)
        }
    }

    func testCreateFinalGoalRejectsZeroCalendarDays() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        XCTAssertThrowsError(try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Pass IELTS",
            targetCalendarDays: 0,
            startDay: startDay
        ))) { error in
            XCTAssertEqual(error as? GoalRepositoryError, .invalidTargetCalendarDays)
        }
    }

    func testCreateFinalGoalAllowsNilCalendarDays() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let id = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Open-ended goal",
            targetCalendarDays: nil,
            startDay: startDay
        ))
        let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == id })
        XCTAssertNil(snapshot.targetCalendarDays)
        XCTAssertNil(snapshot.remainingCalendarDays)
    }

    func testRemainingCalendarDaysUsesInjectedLocalDayAndClampsAtZero() throws {
        let today = try XCTUnwrap(LocalDay(rawValue: "2026-05-13"))
        let fixture = try makeFixture(today: today)

        _ = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Starts today",
            targetCalendarDays: 10,
            startDay: today
        ))
        _ = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Started earlier",
            targetCalendarDays: 10,
            startDay: try XCTUnwrap(LocalDay(rawValue: "2026-05-10"))
        ))
        _ = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Expired",
            targetCalendarDays: 5,
            startDay: try XCTUnwrap(LocalDay(rawValue: "2026-05-01"))
        ))

        let snapshots = try fixture.repository.finalGoalsForList()

        XCTAssertEqual(snapshots.first { $0.title == "Starts today" }?.remainingCalendarDays, 10)
        XCTAssertEqual(snapshots.first { $0.title == "Started earlier" }?.remainingCalendarDays, 7)
        XCTAssertEqual(snapshots.first { $0.title == "Expired" }?.remainingCalendarDays, 0)
    }

    func testCreateFinalGoalStoresPresetAndCustomColors() throws {
        let fixture = try makeFixture()
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let presetID = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Preset",
            colorThemeID: FinalGoalColorTheme.orange.id,
            startDay: startDay
        ))
        let customID = try fixture.repository.createFinalGoal(CreateFinalGoalInput(
            title: "Custom",
            colorThemeID: FinalGoalColorTheme.customID,
            customColorHex: "abc",
            startDay: startDay
        ))

        let snapshots = try fixture.repository.finalGoalsForList()
        let preset = try XCTUnwrap(snapshots.first { $0.id == presetID })
        let custom = try XCTUnwrap(snapshots.first { $0.id == customID })
        XCTAssertEqual(preset.colorThemeID, FinalGoalColorTheme.orange.id)
        XCTAssertNil(preset.customColorHex)
        XCTAssertEqual(preset.colorHex, FinalGoalColorTheme.orange.hex)
        XCTAssertEqual(custom.colorThemeID, FinalGoalColorTheme.customID)
        XCTAssertEqual(custom.customColorHex, "#AABBCC")
        XCTAssertEqual(custom.colorHex, "#AABBCC")
    }

    // MARK: - Update

    func testUpdateFinalGoalAppliesTrimmedValues() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let id = try fixture.createFinalGoal(title: "Old Title", day: day)

        try fixture.repository.updateFinalGoal(
            finalGoalID: id,
            input: UpdateFinalGoalInput(
                title: "  New Title  ",
                goalDescription: "  Updated  ",
                targetCalendarDays: 200,
                colorThemeID: FinalGoalColorTheme.customID,
                customColorHex: "#123abc"
            )
        )

        let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == id })
        XCTAssertEqual(snapshot.title, "New Title")
        XCTAssertEqual(snapshot.goalDescription, "Updated")
        XCTAssertEqual(snapshot.targetCalendarDays, 200)
        XCTAssertEqual(snapshot.colorThemeID, FinalGoalColorTheme.customID)
        XCTAssertEqual(snapshot.customColorHex, "#123ABC")
        XCTAssertEqual(snapshot.colorHex, "#123ABC")
    }

    // MARK: - Move

    func testMoveActiveFinalGoalReorders() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let first = try fixture.createFinalGoal(title: "First", day: day)
        let archived = try fixture.createFinalGoal(title: "Archived", day: day)
        let third = try fixture.createFinalGoal(title: "Third", day: day)
        try fixture.repository.setFinalGoalArchived(finalGoalID: archived, isArchived: true)

        try fixture.repository.moveActiveFinalGoal(finalGoalID: third, toIndex: 0)

        let snapshots = try fixture.repository.finalGoalsForList()
        let activeIDs = snapshots.filter { $0.archivedAt == nil }.map(\.id)
        XCTAssertEqual(activeIDs, [third, first])
    }

    // MARK: - Archive State

    func testSetFinalGoalArchivedArchivesActiveGoal() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        XCTAssertNotNil(snapshot.archivedAt)
    }

    func testSetFinalGoalArchivedReactivatesArchivedGoal() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)
        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: false)

        let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        XCTAssertNil(snapshot.archivedAt)
    }

    func testSetFinalGoalArchivedIsIdempotent() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)
        var snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        let firstArchivedAt = try XCTUnwrap(snapshot.archivedAt)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)
        snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        XCTAssertEqual(snapshot.archivedAt, firstArchivedAt)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: false)
        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: false)
        snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        XCTAssertNil(snapshot.archivedAt)
    }

    func testSetFinalGoalArchivedPreservesMilestones() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        try fixture.repository.setFinalGoalArchived(finalGoalID: fgID, isArchived: true)

        let milestones = try fixture.fetchMilestones(for: fgID)
        XCTAssertEqual(milestones.count, 1)
        XCTAssertNil(milestones[0].completedAt)
    }

    // MARK: - Delete

    func testDeleteFinalGoalCascadeDeletesMilestones() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        try fixture.repository.deleteFinalGoal(finalGoalID: fgID)

        XCTAssertEqual(try fixture.repository.finalGoalsForList().count, 0)
        XCTAssertEqual(try fixture.fetchAllMilestones().count, 0)
    }

    // MARK: - List Snapshot

    func testFinalGoalsForListShowsMilestoneProgress() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        let m2 = try fixture.createMilestone(title: "Phase 2", targetDays: 10, finalGoalID: fgID)

        // Activate second milestone (first will be completed)
        let milestoneRepo = MilestoneGoalRepository(modelContext: fixture.modelContext)
        try milestoneRepo.setMilestoneActive(milestoneGoalID: m2, isActive: true)

        // Complete first milestone
        let milestones = try fixture.fetchMilestones(for: fgID)
        milestones.first { $0.id == m1 }?.completedAt = Date()
        try fixture.save()

        let goals = try fixture.repository.finalGoalsForList()
        let snapshot = try XCTUnwrap(goals.first { $0.id == fgID })
        XCTAssertEqual(snapshot.completedMilestoneCount, 1)
        XCTAssertEqual(snapshot.totalMilestoneCount, 2)
        XCTAssertEqual(snapshot.activeMilestoneCount, 1)
        XCTAssertNil(snapshot.archivedAt)
    }

    func testFinalGoalsForListDoesNotCountCompletedMilestonesAsActive() throws {
        let fixture = try makeFixture()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
        let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)

        let milestoneRepo = MilestoneGoalRepository(modelContext: fixture.modelContext)
        try milestoneRepo.setMilestoneActive(milestoneGoalID: m1, isActive: true)
        try milestoneRepo.completeToday(milestoneGoalID: m1, day: day)

        let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
        XCTAssertEqual(snapshot.completedMilestoneCount, 1)
        XCTAssertEqual(snapshot.activeMilestoneCount, 0)
    }

    // MARK: - Helpers

    private func makeFixture(today: LocalDay = .today) throws -> FinalGoalRepositoryFixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        return FinalGoalRepositoryFixture(
            modelContext: context,
            repository: FinalGoalRepository(modelContext: context, today: { today })
        )
    }
}

@MainActor
private struct FinalGoalRepositoryFixture {
    let modelContext: ModelContext
    let repository: FinalGoalRepository

    func createFinalGoal(title: String, day: LocalDay) throws -> UUID {
        try repository.createFinalGoal(CreateFinalGoalInput(title: title, startDay: day))
    }

    func createMilestone(title: String, targetDays: Int, finalGoalID: UUID) throws -> UUID {
        try MilestoneGoalRepository(modelContext: modelContext).createMilestoneGoal(CreateMilestoneGoalInput(
            title: title,
            targetCompletionTimes: targetDays,
            finalGoalID: finalGoalID
        ))
    }

    func fetchMilestones(for finalGoalID: UUID) throws -> [MilestoneGoal] {
        let descriptor = FetchDescriptor<MilestoneGoal>(
            predicate: #Predicate { $0.finalGoalID == finalGoalID },
            sortBy: [SortDescriptor(\MilestoneGoal.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllMilestones() throws -> [MilestoneGoal] {
        try modelContext.fetch(FetchDescriptor<MilestoneGoal>())
    }

    func save() throws {
        try modelContext.save()
    }
}
