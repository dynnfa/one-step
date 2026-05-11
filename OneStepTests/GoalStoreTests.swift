import SwiftData
import XCTest
import OneStepCore
@testable import OneStep

@MainActor
final class FinalGoalStoreTests: XCTestCase {
    func testRefreshLoadsFinalGoalsFromRepository() throws {
        let fixture = try makeFixture()

        _ = try fixture.finalGoalRepo.createFinalGoal(CreateFinalGoalInput(
            title: "Pass IELTS",
            startDay: fixture.day
        ))

        fixture.store.refresh()

        XCTAssertEqual(fixture.store.finalGoals.map(\.title), ["Pass IELTS"])
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testCreateFinalGoalMarksFirstGoalAndRefreshes() throws {
        let fixture = try makeFixture()

        fixture.store.createFinalGoal(title: "Pass IELTS", goalDescription: nil, targetCalendarDays: nil)

        XCTAssertTrue(fixture.store.didCreateFirstGoal)
        XCTAssertEqual(fixture.store.finalGoals.map(\.title), ["Pass IELTS"])
    }

    func testUpdateFinalGoalRefreshesListAndReportsErrors() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "Old", goalDescription: nil, targetCalendarDays: nil)
        let fgID = try XCTUnwrap(fixture.store.finalGoals.first?.id)

        fixture.store.updateFinalGoal(finalGoalID: fgID, title: "New", goalDescription: "Updated", targetCalendarDays: 200)
        XCTAssertEqual(fixture.store.finalGoals.first?.title, "New")
        XCTAssertNil(fixture.store.errorMessage)

        fixture.store.updateFinalGoal(finalGoalID: fgID, title: "   ", goalDescription: nil, targetCalendarDays: nil)
        XCTAssertEqual(fixture.store.errorMessage, GoalRepositoryError.invalidTitle.localizedDescription)
    }

    func testToggleFinalGoalArchiveUpdatesListState() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "First", goalDescription: nil, targetCalendarDays: nil)
        fixture.store.createFinalGoal(title: "Second", goalDescription: nil, targetCalendarDays: nil)
        let firstID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "First" }?.id)
        let secondID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "Second" }?.id)

        fixture.store.toggleFinalGoalArchive(finalGoalID: firstID)
        XCTAssertNotNil(fixture.store.finalGoals.first { $0.id == firstID }?.archivedAt)

        fixture.store.move(from: IndexSet(integer: 1), to: 0)
        let activeGoals = fixture.store.finalGoals.filter { $0.archivedAt == nil }
        XCTAssertEqual(activeGoals.map(\.id), [secondID])

        fixture.store.toggleFinalGoalArchive(finalGoalID: firstID)
        XCTAssertNil(fixture.store.finalGoals.first { $0.id == firstID }?.archivedAt)
    }

    func testMoveReordersActiveGoalsLocallyAndPreservesArchivedGoals() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "First", goalDescription: nil, targetCalendarDays: nil)
        fixture.store.createFinalGoal(title: "Archived", goalDescription: nil, targetCalendarDays: nil)
        fixture.store.createFinalGoal(title: "Third", goalDescription: nil, targetCalendarDays: nil)
        let firstID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "First" }?.id)
        let archivedID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "Archived" }?.id)
        let thirdID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "Third" }?.id)
        fixture.store.toggleFinalGoalArchive(finalGoalID: archivedID)

        fixture.store.move(from: IndexSet(integer: 1), to: 0)

        let activeIDs = fixture.store.finalGoals.filter { $0.archivedAt == nil }.map(\.id)
        XCTAssertEqual(activeIDs, [thirdID, firstID])
        XCTAssertNotNil(fixture.store.finalGoals.first { $0.id == archivedID }?.archivedAt)
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testMoveClampsNegativeDestinationLocally() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "First", goalDescription: nil, targetCalendarDays: nil)
        fixture.store.createFinalGoal(title: "Second", goalDescription: nil, targetCalendarDays: nil)
        let firstID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "First" }?.id)
        let secondID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "Second" }?.id)

        fixture.store.move(from: IndexSet(integer: 1), to: -10)

        let activeIDs = fixture.store.finalGoals.filter { $0.archivedAt == nil }.map(\.id)
        XCTAssertEqual(activeIDs, [secondID, firstID])
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testFinalGoalDetailActionPolicyMakesArchivedGoalsReadOnly() {
        let activePolicy = FinalGoalDetailActionPolicy(goal: makeSnapshot(archivedAt: nil))
        XCTAssertTrue(activePolicy.canMutateGoal)
        XCTAssertTrue(activePolicy.canMutateMilestones)
        XCTAssertEqual(activePolicy.archiveButtonTitle, "Archive Goal")

        let archivedPolicy = FinalGoalDetailActionPolicy(goal: makeSnapshot(archivedAt: Date()))
        XCTAssertFalse(archivedPolicy.canMutateGoal)
        XCTAssertFalse(archivedPolicy.canMutateMilestones)
        XCTAssertEqual(archivedPolicy.archiveButtonTitle, "Reactivate Goal")
    }

    func testDeleteFinalGoalRemovesItFromListAndClearsSelection() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "First", goalDescription: nil, targetCalendarDays: nil)
        fixture.store.createFinalGoal(title: "Second", goalDescription: nil, targetCalendarDays: nil)
        let firstID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "First" }?.id)

        fixture.store.select(firstID)
        fixture.store.deleteFinalGoal(finalGoalID: firstID)

        XCTAssertEqual(fixture.store.finalGoals.map(\.title), ["Second"])
        XCTAssertNil(fixture.store.selectedFinalGoalID)
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testDataPortStoreExportsBackupFileData() throws {
        let fixture = try makeFixture()
        fixture.store.createFinalGoal(title: "Pass IELTS", goalDescription: "Score 7.0+", targetCalendarDays: 180)
        let dataPortStore = DataPortStore(repository: OneStepBackupRepository(modelContext: fixture.modelContext))

        let file = dataPortStore.makeExportFile()

        XCTAssertNotNil(file)
        XCTAssertEqual(dataPortStore.statusMessage, "Export is ready.")
        let data = try XCTUnwrap(file?.data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(OneStepBackupDocument.self, from: data)
        XCTAssertEqual(document.finalGoals.map(\.title), ["Pass IELTS"])
    }

    func testDataPortStoreImportsBackupDataAndReportsSuccess() throws {
        let fixture = try makeFixture()
        let finalGoalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let document = OneStepBackupDocument(
            exportedAt: Date(timeIntervalSince1970: 1_777_000_000),
            finalGoals: [
                .init(
                    id: finalGoalID,
                    title: "Imported",
                    goalDescription: nil,
                    targetCalendarDays: nil,
                    startDayKey: "2026-04-29",
                    sortOrder: 0,
                    archivedAt: nil,
                    createdAt: Date(timeIntervalSince1970: 1_777_000_000),
                    updatedAt: Date(timeIntervalSince1970: 1_777_000_000)
                )
            ],
            milestones: [],
            dailyCompletions: []
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(document)
        let dataPortStore = DataPortStore(repository: OneStepBackupRepository(modelContext: fixture.modelContext))

        dataPortStore.importData(data)

        fixture.store.refresh()
        XCTAssertEqual(fixture.store.finalGoals.map(\.title), ["Imported"])
        XCTAssertEqual(dataPortStore.statusMessage, "Import complete.")
        XCTAssertNil(dataPortStore.errorMessage)
    }

    func testOneStepBackupFileReadsAndWritesData() throws {
        let input = Data("{}".utf8)
        let file = OneStepBackupFile(data: input)

        let written = file.makeFileWrapper()
        let read = try OneStepBackupFile(fileWrapper: written)

        XCTAssertEqual(read.data, input)
        XCTAssertTrue(OneStepBackupFile.readableContentTypes.contains(.oneStepBackup))
        XCTAssertTrue(OneStepBackupFile.readableContentTypes.contains(.json))
        XCTAssertEqual(OneStepBackupFile.writableContentTypes, [.oneStepBackup])
    }

    func testDataPortStoreDefaultExportFilenameUsesCurrentDay() {
        let date = Date(timeIntervalSince1970: 1_777_000_000)

        XCTAssertEqual(DataPortStore.defaultExportFilename(now: date), "OneStep-Backup-2026-04-24")
    }

    private func makeFixture() throws -> Fixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let fgRepo = FinalGoalRepository(modelContext: context)
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        return Fixture(
            modelContext: context,
            finalGoalRepo: fgRepo,
            store: FinalGoalStore(repository: fgRepo),
            day: day
        )
    }

    private func makeSnapshot(archivedAt: Date?) -> FinalGoalListSnapshot {
        FinalGoalListSnapshot(
            id: UUID(),
            title: "Goal",
            goalDescription: nil,
            targetCalendarDays: nil,
            completedMilestoneCount: 0,
            totalMilestoneCount: 0,
            activeMilestoneCount: 0,
            remainingCalendarDays: nil,
            sortOrder: 0,
            archivedAt: archivedAt
        )
    }
}

@MainActor
private struct Fixture {
    let modelContext: ModelContext
    let finalGoalRepo: FinalGoalRepository
    let store: FinalGoalStore
    let day: LocalDay
}

@MainActor
final class MilestoneGoalStoreTests: XCTestCase {
    func testRefreshLoadsMilestonesForFinalGoal() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)

        XCTAssertEqual(fixture.store.milestones.map(\.title), ["Phase 1"])
        XCTAssertFalse(fixture.store.milestones.first?.isActive ?? true)
    }

    func testCreateAndCheckInRefreshesState() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)

        fixture.store.createMilestone(title: "Phase 1", targetCompletionDays: 5, finalGoalID: fgID)
        let mID = try XCTUnwrap(fixture.store.milestones.first?.id)

        XCTAssertFalse(fixture.store.milestones.first?.isActive ?? true)

        fixture.store.setMilestoneActive(milestoneGoalID: mID, finalGoalID: fgID, isActive: true)
        fixture.store.completeToday(milestoneGoalID: mID, finalGoalID: fgID)
        XCTAssertEqual(fixture.store.milestones.first?.completedDays, 1)
        XCTAssertTrue(fixture.store.milestones.first?.isCompletedToday ?? false)

        fixture.store.uncompleteToday(milestoneGoalID: mID, finalGoalID: fgID)
        XCTAssertEqual(fixture.store.milestones.first?.completedDays, 0)
    }

    func testOnlyFirstIncompleteMilestoneIsActive() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)

        XCTAssertEqual(fixture.store.milestones.map(\.isActive), [false, false])
    }

    func testDeleteMilestoneRemovesItFromMilestones() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let firstID = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)
        _ = try fixture.createMilestone(title: "Phase 2", targetDays: 10, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)
        fixture.store.deleteMilestone(milestoneGoalID: firstID, finalGoalID: fgID)

        XCTAssertEqual(fixture.store.milestones.map(\.title), ["Phase 2"])
        XCTAssertNil(fixture.store.errorMessage)
    }

    func testMilestoneChangesCanRefreshFinalGoalSnapshotCounts() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let finalGoalStore = FinalGoalStore(repository: fixture.fgRepo)

        finalGoalStore.refresh()
        XCTAssertEqual(finalGoalStore.finalGoals.first?.totalMilestoneCount, 0)

        fixture.store.onMilestonesChanged = {
            finalGoalStore.refresh()
        }

        fixture.store.createMilestone(title: "Phase 1", targetCompletionDays: 1, finalGoalID: fgID)
        let milestoneID = try XCTUnwrap(fixture.store.milestones.first?.id)

        XCTAssertEqual(finalGoalStore.finalGoals.first?.totalMilestoneCount, 1)

        fixture.store.setMilestoneActive(milestoneGoalID: milestoneID, finalGoalID: fgID, isActive: true)
        fixture.store.completeToday(milestoneGoalID: milestoneID, finalGoalID: fgID)

        XCTAssertEqual(finalGoalStore.finalGoals.first?.completedMilestoneCount, 1)
    }

    func testDeletingMilestoneCanRefreshFinalGoalSnapshotCounts() throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        let finalGoalStore = FinalGoalStore(repository: fixture.fgRepo)
        let milestoneID = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

        finalGoalStore.refresh()
        XCTAssertEqual(finalGoalStore.finalGoals.first?.totalMilestoneCount, 1)

        fixture.store.deleteMilestone(milestoneGoalID: milestoneID, finalGoalID: fgID)
        finalGoalStore.refresh()

        XCTAssertEqual(finalGoalStore.finalGoals.first?.totalMilestoneCount, 0)
    }

    func testEnsuringLargerRecentActivityDayLimitRefreshesMilestones() async throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 60, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)
        XCTAssertEqual(fixture.store.milestones.first?.recentActivity.count, 30)

        fixture.store.ensureRecentActivityDayLimit(44, finalGoalID: fgID, day: fixture.day)
        await Task.yield()

        XCTAssertEqual(fixture.store.milestones.first?.recentActivity.count, 44)
    }

    func testRecentActivityDayLimitGrowthCoalescesBeforeRefreshing() async throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 90, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)

        fixture.store.ensureRecentActivityDayLimit(44, finalGoalID: fgID, day: fixture.day)
        fixture.store.ensureRecentActivityDayLimit(60, finalGoalID: fgID, day: fixture.day)

        XCTAssertEqual(fixture.store.milestones.first?.recentActivity.count, 30)

        await Task.yield()

        XCTAssertEqual(fixture.store.milestones.first?.recentActivity.count, 60)
    }

    func testEnsuringSmallerRecentActivityDayLimitDoesNotShrinkLoadedActivity() async throws {
        let fixture = try makeFixture()
        let fgID = try fixture.createFinalGoal()
        _ = try fixture.createMilestone(title: "Phase 1", targetDays: 60, finalGoalID: fgID)

        fixture.store.refresh(finalGoalID: fgID, day: fixture.day)
        fixture.store.ensureRecentActivityDayLimit(44, finalGoalID: fgID, day: fixture.day)
        await Task.yield()
        fixture.store.ensureRecentActivityDayLimit(10, finalGoalID: fgID, day: fixture.day)

        XCTAssertEqual(fixture.store.milestones.first?.recentActivity.count, 44)
    }

    private func makeFixture() throws -> MilestoneStoreFixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let fgRepo = FinalGoalRepository(modelContext: context)
        let msRepo = MilestoneGoalRepository(modelContext: context)
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        return MilestoneStoreFixture(
            fgRepo: fgRepo,
            msRepo: msRepo,
            store: MilestoneGoalStore(repository: msRepo),
            day: day
        )
    }
}

final class GoalReorderIndexTests: XCTestCase {
    // Tests computeGoalReorderIndex(source:dest:insertAbove:)
    // which computes the target index for FinalGoalStore.move(from:to:)
    // The "to" index follows Swift's Array remove-then-insert convention.

    // MARK: - Insert Above

    func testInsertAboveLowerIndex() {
        // [A, B, C, D] — drag D(3) above B(1)
        // Remove D → [A, B, C], insert at 1 → [A, D, B, C]
        let result = computeGoalReorderIndex(source: 3, dest: 1, insertAbove: true)
        XCTAssertEqual(result, 1)
    }

    func testInsertAboveUpperIndex() {
        // [A, B, C, D] — drag A(0) above C(2)
        // dest=2, source(0)<2 → insertionIndex=1
        // Remove A → [B, C, D], insert at 1 → [B, A, C, D]
        let result = computeGoalReorderIndex(source: 0, dest: 2, insertAbove: true)
        XCTAssertEqual(result, 1)
    }

    func testInsertAboveSameIndex() {
        // [A, B, C] — drag A(0) above A(0) — no-op but compute anyway
        let result = computeGoalReorderIndex(source: 0, dest: 0, insertAbove: true)
        XCTAssertEqual(result, 0)
    }

    func testInsertAboveFirstPosition() {
        // [A, B, C] — drag C(2) above A(0)
        // Remove C → [A, B], insert at 0 → [C, A, B]
        let result = computeGoalReorderIndex(source: 2, dest: 0, insertAbove: true)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Insert Below

    func testInsertBelowLowerIndex() {
        // [A, B, C, D] — drag A(0) below B(1)
        // Remove A → [B, C, D], insert at 2 → [B, C, A, D]
        // Wait — "below B" means after B. After removing A (index 0 < 2), shift: 2-1=1
        // Result: [B, A, C, D]
        let result = computeGoalReorderIndex(source: 0, dest: 1, insertAbove: false)
        XCTAssertEqual(result, 1)
    }

    func testInsertBelowUpperIndex() {
        // [A, B, C, D] — drag D(3) below A(0)
        // Remove D → [A, B, C], insert at 1 → [A, D, B, C]
        let result = computeGoalReorderIndex(source: 3, dest: 0, insertAbove: false)
        XCTAssertEqual(result, 1)
    }

    func testInsertBelowLastPosition() {
        // [A, B, C] — drag A(0) below C(2)
        // Remove A → [B, C], insert at 3, adjust: source(0) < 3 → 2
        // → [B, C, A]
        let result = computeGoalReorderIndex(source: 0, dest: 2, insertAbove: false)
        XCTAssertEqual(result, 2)
    }

    func testInsertBelowAdjacentForward() {
        // [A, B, C] — drag A(0) below B(1)
        // Remove A → [B, C], dest+1=2, source(0)<2 → 1
        // → [B, A, C]
        let result = computeGoalReorderIndex(source: 0, dest: 1, insertAbove: false)
        XCTAssertEqual(result, 1)
    }

    func testInsertBelowAdjacentBackward() {
        // [A, B, C] — drag C(2) below A(0)
        // dest+1=1, source(2) > 1 → no adjustment → 1
        // → [A, C, B]
        let result = computeGoalReorderIndex(source: 2, dest: 0, insertAbove: false)
        XCTAssertEqual(result, 1)
    }

    // MARK: - Edge cases

    func testTwoItemsInsertAbove() {
        // [A, B] — drag B(1) above A(0)
        // Remove B → [A], insert at 0 → [B, A]
        let result = computeGoalReorderIndex(source: 1, dest: 0, insertAbove: true)
        XCTAssertEqual(result, 0)
    }

    func testTwoItemsInsertBelow() {
        // [A, B] — drag A(0) below B(1)
        // dest+1=2, source(0)<2 → 1
        // → [B, A]
        let result = computeGoalReorderIndex(source: 0, dest: 1, insertAbove: false)
        XCTAssertEqual(result, 1)
    }
}

final class DayCountInputValidatorTests: XCTestCase {
    func testAcceptsTrimmedIntegerWithinRange() {
        XCTAssertEqual(DayCountInputValidator.parse(" 365 ", range: 1...10_000), 365)
    }

    func testRejectsEmptyZeroNegativeTextAndOutOfRangeValues() {
        XCTAssertNil(DayCountInputValidator.parse("", range: 1...10_000))
        XCTAssertNil(DayCountInputValidator.parse("0", range: 1...10_000))
        XCTAssertNil(DayCountInputValidator.parse("-1", range: 1...10_000))
        XCTAssertNil(DayCountInputValidator.parse("abc", range: 1...10_000))
        XCTAssertNil(DayCountInputValidator.parse("10001", range: 1...10_000))
    }
}

final class VisibleActivityDayCountTests: XCTestCase {
    func testUsesFallbackForMissingAndNonFiniteWidths() {
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: nil, activityCount: 60, targetCompletionDays: 60), 30)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: .infinity, activityCount: 60, targetCompletionDays: 60), 30)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: .nan, activityCount: 60, targetCompletionDays: 60), 30)
    }

    func testFiniteWidthsShowAtLeastOneExistingDay() {
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 0, activityCount: 60, targetCompletionDays: 60), 1)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 7, activityCount: 60, targetCompletionDays: 60), 1)
    }

    func testFiniteWidthsUseCellWidthAndSpacingCapacity() {
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 8, activityCount: 60, targetCompletionDays: 60), 1)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 19, activityCount: 60, targetCompletionDays: 60), 2)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 327, activityCount: 60, targetCompletionDays: 60), 30)
    }

    func testVisibleDaysAreCappedByActivityAndTargetCounts() {
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 327, activityCount: 7, targetCompletionDays: 30), 7)
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 327, activityCount: 60, targetCompletionDays: 7), 7)
    }

    func testEmptyActivityShowsNoDays() {
        XCTAssertEqual(RecentActivityLayout.computeVisibleDayCount(availableWidth: 327, activityCount: 0, targetCompletionDays: 30), 0)
    }
}

@MainActor
private struct MilestoneStoreFixture {
    let fgRepo: FinalGoalRepository
    let msRepo: MilestoneGoalRepository
    let store: MilestoneGoalStore
    let day: LocalDay

    func createFinalGoal() throws -> UUID {
        try fgRepo.createFinalGoal(CreateFinalGoalInput(title: "Test Goal", startDay: day))
    }

    func createMilestone(title: String, targetDays: Int, finalGoalID: UUID) throws -> UUID {
        try msRepo.createMilestoneGoal(CreateMilestoneGoalInput(
            title: title, targetCompletionDays: targetDays, finalGoalID: finalGoalID
        ))
    }
}
