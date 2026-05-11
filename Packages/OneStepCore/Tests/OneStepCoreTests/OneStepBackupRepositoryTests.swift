import SwiftData
import XCTest
@testable import OneStepCore

@MainActor
final class OneStepBackupRepositoryTests: XCTestCase {
    func testExportDocumentIncludesGoalsMilestonesAndCompletions() throws {
        let fixture = try makeFixture()
        let finalGoalID = try fixture.createFinalGoal(title: "Pass IELTS")
        let milestoneID = try fixture.createMilestone(title: "Listening", targetDays: 2, finalGoalID: finalGoalID)
        try fixture.milestoneRepository.setMilestoneActive(milestoneGoalID: milestoneID, isActive: true)
        let completionDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        try fixture.milestoneRepository.completeToday(milestoneGoalID: milestoneID, day: completionDay)

        let document = try fixture.backupRepository.exportDocument(exportedAt: Date(timeIntervalSince1970: 1_777_000_000))

        XCTAssertEqual(document.schemaVersion, 1)
        XCTAssertEqual(document.finalGoals.map(\.id), [finalGoalID])
        XCTAssertEqual(document.finalGoals.first?.title, "Pass IELTS")
        XCTAssertEqual(document.milestones.map(\.id), [milestoneID])
        XCTAssertEqual(document.milestones.first?.finalGoalID, finalGoalID)
        XCTAssertEqual(document.dailyCompletions.map(\.goalID), [milestoneID])
        XCTAssertEqual(document.dailyCompletions.map(\.dayKey), ["2026-04-29"])
    }

    func testImportDocumentReplacesExistingDataAndPreservesFields() throws {
        let fixture = try makeFixture()
        _ = try fixture.createFinalGoal(title: "Existing")
        let document = makeImportDocument()

        try fixture.backupRepository.importDocument(document)

        let goals = try fixture.fetchFinalGoals()
        let milestones = try fixture.fetchMilestones()
        let completions = try fixture.fetchCompletions()
        XCTAssertEqual(goals.map(\.id), [document.finalGoals[0].id])
        XCTAssertEqual(goals.first?.title, "Imported Goal")
        XCTAssertEqual(goals.first?.goalDescription, "Restored")
        XCTAssertEqual(goals.first?.targetCalendarDays, 90)
        XCTAssertEqual(goals.first?.startDayKey, "2026-04-01")
        XCTAssertEqual(goals.first?.sortOrder, 7)
        XCTAssertEqual(goals.first?.archivedAt, Date(timeIntervalSince1970: 1_777_000_120))
        XCTAssertEqual(goals.first?.createdAt, Date(timeIntervalSince1970: 1_777_000_000))
        XCTAssertEqual(goals.first?.updatedAt, Date(timeIntervalSince1970: 1_777_000_060))
        XCTAssertEqual(milestones.map(\.id), [document.milestones[0].id])
        XCTAssertEqual(milestones.first?.title, "Imported Milestone")
        XCTAssertEqual(milestones.first?.targetCompletionDays, 12)
        XCTAssertEqual(milestones.first?.finalGoalID, document.finalGoals[0].id)
        XCTAssertEqual(milestones.first?.sortOrder, 3)
        XCTAssertEqual(milestones.first?.isActive, false)
        XCTAssertEqual(milestones.first?.startDayKey, "2026-04-02")
        XCTAssertEqual(milestones.first?.completedAt, Date(timeIntervalSince1970: 1_777_000_180))
        XCTAssertEqual(completions.map(\.id), [document.dailyCompletions[0].id])
        XCTAssertEqual(completions.first?.uniqueKey, DailyCompletion.makeUniqueKey(goalID: document.milestones[0].id, dayKey: "2026-04-03"))
    }

    func testImportDocumentSavesReplacementOnce() throws {
        let fixture = try makeFixture()
        _ = try fixture.createFinalGoal(title: "Existing")
        let document = makeImportDocument()
        var saveCount = 0
        let backupRepository = OneStepBackupRepository(modelContext: fixture.modelContext) { context in
            saveCount += 1
            try context.save()
        }

        try backupRepository.importDocument(document)

        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(try fixture.fetchFinalGoals().map(\.title), ["Imported Goal"])
    }

    func testImportDocumentRollsBackWhenSaveFails() throws {
        let fixture = try makeFixture()
        _ = try fixture.createFinalGoal(title: "Existing")
        let document = makeImportDocument()
        let backupRepository = OneStepBackupRepository(modelContext: fixture.modelContext) { _ in
            throw NSError(domain: "OneStepBackupRepositoryTests", code: 1)
        }

        XCTAssertThrowsError(try backupRepository.importDocument(document))
        XCTAssertEqual(try fixture.fetchFinalGoals().map(\.title), ["Existing"])
    }

    func testImportRejectsUnsupportedSchemaVersionAndKeepsExistingData() throws {
        let fixture = try makeFixture()
        _ = try fixture.createFinalGoal(title: "Existing")
        let document = makeImportDocument(schemaVersion: 99)

        XCTAssertThrowsError(try fixture.backupRepository.importDocument(document)) { error in
            XCTAssertEqual(error as? OneStepBackupError, .unsupportedSchemaVersion(99))
        }
        XCTAssertEqual(try fixture.fetchFinalGoals().map(\.title), ["Existing"])
    }

    private func makeImportDocument(schemaVersion: Int = OneStepBackupDocument.currentSchemaVersion) -> OneStepBackupDocument {
        let finalGoalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let milestoneID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let completionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let createdAt = Date(timeIntervalSince1970: 1_777_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_777_000_060)
        let archivedAt = Date(timeIntervalSince1970: 1_777_000_120)
        let completedAt = Date(timeIntervalSince1970: 1_777_000_180)
        return OneStepBackupDocument(
            schemaVersion: schemaVersion,
            exportedAt: Date(timeIntervalSince1970: 1_777_000_240),
            finalGoals: [
                .init(
                    id: finalGoalID,
                    title: "Imported Goal",
                    goalDescription: "Restored",
                    targetCalendarDays: 90,
                    startDayKey: "2026-04-01",
                    sortOrder: 7,
                    archivedAt: archivedAt,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            ],
            milestones: [
                .init(
                    id: milestoneID,
                    title: "Imported Milestone",
                    targetCompletionDays: 12,
                    finalGoalID: finalGoalID,
                    sortOrder: 3,
                    isActive: false,
                    startDayKey: "2026-04-02",
                    completedAt: completedAt,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            ],
            dailyCompletions: [
                .init(id: completionID, goalID: milestoneID, dayKey: "2026-04-03", completedAt: completedAt)
            ]
        )
    }

    func testImportRejectsDanglingMilestoneAndKeepsExistingData() throws {
        let fixture = try makeFixture()
        _ = try fixture.createFinalGoal(title: "Existing")
        let originalGoals = try fixture.fetchFinalGoals().map(\.title)
        let document = OneStepBackupDocument(
            exportedAt: Date(timeIntervalSince1970: 1_777_000_000),
            finalGoals: [],
            milestones: [
                .init(
                    id: UUID(),
                    title: "Orphan",
                    targetCompletionDays: 1,
                    finalGoalID: UUID(),
                    sortOrder: 0,
                    isActive: false,
                    startDayKey: nil,
                    completedAt: nil,
                    createdAt: Date(timeIntervalSince1970: 1_777_000_000),
                    updatedAt: Date(timeIntervalSince1970: 1_777_000_000)
                )
            ],
            dailyCompletions: []
        )

        XCTAssertThrowsError(try fixture.backupRepository.importDocument(document)) { error in
            XCTAssertEqual(error as? OneStepBackupError, .missingFinalGoalForMilestone)
        }
        XCTAssertEqual(try fixture.fetchFinalGoals().map(\.title), originalGoals)
    }

    func testImportRejectsDuplicateDailyCompletion() throws {
        let fixture = try makeFixture()
        let finalGoalID = UUID()
        let milestoneID = UUID()
        let document = OneStepBackupDocument(
            exportedAt: Date(timeIntervalSince1970: 1_777_000_000),
            finalGoals: [
                .init(
                    id: finalGoalID,
                    title: "Goal",
                    goalDescription: nil,
                    targetCalendarDays: nil,
                    startDayKey: "2026-04-29",
                    sortOrder: 0,
                    archivedAt: nil,
                    createdAt: Date(timeIntervalSince1970: 1_777_000_000),
                    updatedAt: Date(timeIntervalSince1970: 1_777_000_000)
                )
            ],
            milestones: [
                .init(
                    id: milestoneID,
                    title: "Milestone",
                    targetCompletionDays: 2,
                    finalGoalID: finalGoalID,
                    sortOrder: 0,
                    isActive: true,
                    startDayKey: nil,
                    completedAt: nil,
                    createdAt: Date(timeIntervalSince1970: 1_777_000_000),
                    updatedAt: Date(timeIntervalSince1970: 1_777_000_000)
                )
            ],
            dailyCompletions: [
                .init(id: UUID(), goalID: milestoneID, dayKey: "2026-04-29", completedAt: Date(timeIntervalSince1970: 1_777_000_000)),
                .init(id: UUID(), goalID: milestoneID, dayKey: "2026-04-29", completedAt: Date(timeIntervalSince1970: 1_777_000_060))
            ]
        )

        XCTAssertThrowsError(try fixture.backupRepository.importDocument(document)) { error in
            XCTAssertEqual(error as? OneStepBackupError, .duplicateDailyCompletion)
        }
    }

    private func makeFixture() throws -> Fixture {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        return Fixture(modelContext: context)
    }
}

@MainActor
private struct Fixture {
    let modelContext: ModelContext
    let finalGoalRepository: FinalGoalRepository
    let milestoneRepository: MilestoneGoalRepository
    let backupRepository: OneStepBackupRepository
    let day: LocalDay

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.finalGoalRepository = FinalGoalRepository(modelContext: modelContext)
        self.milestoneRepository = MilestoneGoalRepository(modelContext: modelContext)
        self.backupRepository = OneStepBackupRepository(modelContext: modelContext)
        self.day = LocalDay(rawValue: "2026-04-29")!
    }

    func createFinalGoal(title: String) throws -> UUID {
        try finalGoalRepository.createFinalGoal(CreateFinalGoalInput(title: title, startDay: day))
    }

    func createMilestone(title: String, targetDays: Int, finalGoalID: UUID) throws -> UUID {
        try milestoneRepository.createMilestoneGoal(CreateMilestoneGoalInput(
            title: title,
            targetCompletionDays: targetDays,
            finalGoalID: finalGoalID
        ))
    }

    func fetchFinalGoals() throws -> [FinalGoal] {
        try modelContext.fetch(FetchDescriptor<FinalGoal>(sortBy: [SortDescriptor(\FinalGoal.sortOrder)]))
    }

    func fetchMilestones() throws -> [MilestoneGoal] {
        try modelContext.fetch(FetchDescriptor<MilestoneGoal>(sortBy: [SortDescriptor(\MilestoneGoal.sortOrder)]))
    }

    func fetchCompletions() throws -> [DailyCompletion] {
        try modelContext.fetch(FetchDescriptor<DailyCompletion>(sortBy: [SortDescriptor(\DailyCompletion.dayKey)]))
    }
}
