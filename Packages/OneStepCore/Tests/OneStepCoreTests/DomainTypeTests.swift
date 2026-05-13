import SwiftData
import XCTest
@testable import OneStepCore

final class DomainTypeTests: XCTestCase {
    func testAppIdentifiersCentralizeSharedAppAndWidgetConstants() {
        XCTAssertEqual(AppIdentifiers.appGroupIdentifier, "group.dev.dynnfa.OneStep")
        XCTAssertEqual(AppIdentifiers.widgetKind, "OneStepWidget")
    }

    func testFinalGoalActiveStateOnlyDependsOnArchivedAt() {
        let goal = FinalGoal(
            title: "Pass IELTS",
            startDayKey: "2026-04-30",
            sortOrder: 0
        )

        XCTAssertTrue(goal.isActive)

        goal.archivedAt = Date()
        XCTAssertFalse(goal.isActive)
    }

    func testMilestoneGoalCompletionStateIsStoredWithoutActivationState() {
        let milestone = MilestoneGoal(
            title: "Finish vocabulary",
            targetCompletionDays: 30,
            finalGoalID: UUID(),
            sortOrder: 0
        )

        XCTAssertNil(milestone.completedAt)
        milestone.completedAt = Date()
        XCTAssertNotNil(milestone.completedAt)
    }

    func testDailyCompletionUniqueKeyUsesMilestoneAndDay() throws {
        let container = try OneStepModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let milestoneID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let completion = DailyCompletion(goalID: milestoneID, dayKey: "2026-04-29")
        context.insert(completion)

        XCTAssertEqual(completion.uniqueKey, "00000000-0000-0000-0000-000000000001#2026-04-29")
        XCTAssertEqual(
            DailyCompletion.makeUniqueKey(goalID: milestoneID, dayKey: "2026-04-29"),
            completion.uniqueKey
        )
    }

    func testFinalGoalSnapshotsPreserveValues() throws {
        let startDay = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))

        let createInput = CreateFinalGoalInput(
            title: "Pass IELTS",
            goalDescription: "Score 7.0+",
            targetCalendarDays: 180,
            colorThemeID: FinalGoalColorTheme.green.id,
            customColorHex: nil,
            startDay: startDay
        )
        let updateInput = UpdateFinalGoalInput(
            title: "Pass TOEFL",
            goalDescription: "Score 100+",
            targetCalendarDays: 200,
            colorThemeID: FinalGoalColorTheme.customID,
            customColorHex: "#AABBCC"
        )
        let snapshot = FinalGoalListSnapshot(
            id: UUID(),
            title: createInput.title,
            goalDescription: createInput.goalDescription,
            targetCalendarDays: createInput.targetCalendarDays,
            colorThemeID: createInput.colorThemeID,
            customColorHex: createInput.customColorHex,
            colorHex: FinalGoalColorTheme.green.hex,
            completedMilestoneCount: 1,
            totalMilestoneCount: 3,
            activeMilestoneCount: 2,
            remainingCalendarDays: 150,
            sortOrder: 0,
            archivedAt: nil
        )

        XCTAssertEqual(createInput.startDay, startDay)
        XCTAssertEqual(updateInput.title, "Pass TOEFL")
        XCTAssertEqual(updateInput.customColorHex, "#AABBCC")
        XCTAssertEqual(snapshot.colorHex, "#34C759")
        XCTAssertEqual(snapshot.completedMilestoneCount, 1)
        XCTAssertEqual(snapshot.totalMilestoneCount, 3)
        XCTAssertEqual(snapshot.activeMilestoneCount, 2)
    }

    func testFinalGoalColorThemeNormalizesInputs() {
        XCTAssertEqual(FinalGoalColorTheme.defaultTheme.id, "black")
        XCTAssertEqual(FinalGoalColorTheme.defaultTheme.hex, "#000000")
        XCTAssertEqual(FinalGoalColorTheme.theme(id: "missing").id, "black")
        XCTAssertTrue(FinalGoalColorTheme.presets.contains { $0.id == "black" })
        XCTAssertEqual(FinalGoalColorTheme.normalizedHex("#abc"), "#AABBCC")
        XCTAssertEqual(FinalGoalColorTheme.normalizedHex("12abef"), "#12ABEF")
        XCTAssertNil(FinalGoalColorTheme.normalizedHex("oops"))
        XCTAssertEqual(
            FinalGoalColorTheme.resolvedHex(themeID: FinalGoalColorTheme.customID, customColorHex: "#fedcba"),
            "#FEDCBA"
        )
        XCTAssertEqual(
            FinalGoalColorTheme.resolvedHex(themeID: FinalGoalColorTheme.customID, customColorHex: "oops"),
            FinalGoalColorTheme.defaultTheme.hex
        )
    }

    func testMilestoneSnapshotsPreserveValues() throws {
        let parentID = UUID()
        let milestoneID = UUID()
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        let recentActivity = RecentActivityDay(day: day, isCompleted: true)

        let snapshot = MilestoneGoalSnapshot(
            id: milestoneID,
            title: "Vocabulary",
            targetCompletionDays: 30,
            finalGoalID: parentID,
            sortOrder: 0,
            isActive: true,
            completedDays: 12,
            isCompletedToday: true,
            startDayKey: "2026-04-17",
            completedAt: nil,
            recentActivity: [recentActivity]
        )

        XCTAssertTrue(snapshot.isActive)
        XCTAssertEqual(snapshot.completedDays, 12)
        XCTAssertEqual(snapshot.recentActivity, [recentActivity])
    }

    func testWidgetMilestoneSnapshotPreservesValues() {
        let snapshot = WidgetMilestoneSnapshot(
            id: UUID(),
            title: "Vocabulary",
            parentFinalGoalTitle: "Pass IELTS",
            colorHex: FinalGoalColorTheme.purple.hex,
            targetCompletionDays: 30,
            completedDays: 12,
            isCompletedToday: true
        )

        XCTAssertEqual(snapshot.parentFinalGoalTitle, "Pass IELTS")
        XCTAssertEqual(snapshot.colorHex, "#AF52DE")
        XCTAssertEqual(snapshot.completedDays, 12)
    }

    func testRepositoryErrorsExposeDescriptions() {
        XCTAssertEqual(GoalRepositoryError.finalGoalNotFound.errorDescription, "Final goal not found.")
        XCTAssertEqual(GoalRepositoryError.milestoneGoalNotFound.errorDescription, "Milestone goal not found.")
        XCTAssertEqual(GoalRepositoryError.finalGoalNotActive.errorDescription, "Final goal is archived.")
        XCTAssertEqual(GoalRepositoryError.milestoneNotActive.errorDescription, "Milestone is not current or is already complete.")
        XCTAssertEqual(GoalRepositoryError.saveFailed("disk").errorDescription, "Save failed: disk")
    }
}
