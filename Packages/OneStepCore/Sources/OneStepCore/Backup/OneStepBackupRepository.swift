import Foundation
import SwiftData

@MainActor
public struct OneStepBackupRepository {
    private let modelContext: ModelContext
    private let persist: @MainActor (ModelContext) throws -> Void

    public init(
        modelContext: ModelContext,
        persist: @escaping @MainActor (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.modelContext = modelContext
        self.persist = persist
    }

    public static func shared(appGroupIdentifier: String) throws -> OneStepBackupRepository {
        let container = try OneStepModelContainerFactory.sharedContainer(appGroupIdentifier: appGroupIdentifier)
        return OneStepBackupRepository(modelContext: ModelContext(container))
    }

    public func exportDocument(exportedAt: Date = Date()) throws -> OneStepBackupDocument {
        let finalGoals = try modelContext.fetch(FetchDescriptor<FinalGoal>(
            sortBy: [SortDescriptor(\FinalGoal.sortOrder), SortDescriptor(\FinalGoal.createdAt)]
        ))
        let milestones = try modelContext.fetch(FetchDescriptor<MilestoneGoal>(
            sortBy: [SortDescriptor(\MilestoneGoal.sortOrder), SortDescriptor(\MilestoneGoal.createdAt)]
        ))
        let completions = try modelContext.fetch(FetchDescriptor<DailyCompletion>(
            sortBy: [SortDescriptor(\DailyCompletion.dayKey), SortDescriptor(\DailyCompletion.completedAt)]
        ))

        return OneStepBackupDocument(
            exportedAt: exportedAt,
            finalGoals: finalGoals.map {
                .init(
                    id: $0.id,
                    title: $0.title,
                    goalDescription: $0.goalDescription,
                    targetCalendarDays: $0.targetCalendarDays,
                    startDayKey: $0.startDayKey,
                    sortOrder: $0.sortOrder,
                    archivedAt: $0.archivedAt,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            milestones: milestones.map {
                .init(
                    id: $0.id,
                    title: $0.title,
                    targetCompletionDays: $0.targetCompletionDays,
                    finalGoalID: $0.finalGoalID,
                    sortOrder: $0.sortOrder,
                    isActive: $0.isActive,
                    startDayKey: $0.startDayKey,
                    completedAt: $0.completedAt,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            dailyCompletions: completions.map {
                .init(id: $0.id, goalID: $0.goalID, dayKey: $0.dayKey, completedAt: $0.completedAt)
            }
        )
    }

    public func importDocument(_ document: OneStepBackupDocument) throws {
        try validate(document)

        let snapshot = try snapshotExistingData()
        try deleteExistingRows()

        do {
            for record in document.finalGoals {
                modelContext.insert(FinalGoal(
                    id: record.id,
                    title: record.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    goalDescription: record.goalDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    targetCalendarDays: record.targetCalendarDays,
                    startDayKey: record.startDayKey,
                    sortOrder: record.sortOrder,
                    archivedAt: record.archivedAt,
                    createdAt: record.createdAt,
                    updatedAt: record.updatedAt
                ))
            }

            for record in document.milestones {
                modelContext.insert(MilestoneGoal(
                    id: record.id,
                    title: record.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    targetCompletionDays: record.targetCompletionDays,
                    finalGoalID: record.finalGoalID,
                    sortOrder: record.sortOrder,
                    isActive: record.isActive,
                    startDayKey: record.startDayKey,
                    completedAt: record.completedAt,
                    createdAt: record.createdAt,
                    updatedAt: record.updatedAt
                ))
            }

            for record in document.dailyCompletions {
                modelContext.insert(DailyCompletion(
                    id: record.id,
                    goalID: record.goalID,
                    dayKey: record.dayKey,
                    completedAt: record.completedAt
                ))
            }

            try save()
        } catch {
            restoreFromSnapshot(snapshot)
            throw error
        }
    }
}

@MainActor
private extension OneStepBackupRepository {
    func validate(_ document: OneStepBackupDocument) throws {
        guard document.schemaVersion == OneStepBackupDocument.currentSchemaVersion else {
            throw OneStepBackupError.unsupportedSchemaVersion(document.schemaVersion)
        }

        var finalGoalIDs: Set<UUID> = []
        for record in document.finalGoals {
            guard finalGoalIDs.insert(record.id).inserted else { throw OneStepBackupError.duplicateFinalGoalID }
            guard !record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OneStepBackupError.invalidFinalGoalTitle
            }
            guard LocalDay(rawValue: record.startDayKey) != nil else {
                throw OneStepBackupError.invalidFinalGoalStartDay
            }
            if let days = record.targetCalendarDays, days <= 0 {
                throw OneStepBackupError.invalidTargetCalendarDays
            }
        }

        var milestoneIDs: Set<UUID> = []
        for record in document.milestones {
            guard milestoneIDs.insert(record.id).inserted else { throw OneStepBackupError.duplicateMilestoneGoalID }
            guard finalGoalIDs.contains(record.finalGoalID) else { throw OneStepBackupError.missingFinalGoalForMilestone }
            guard !record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OneStepBackupError.invalidMilestoneTitle
            }
            guard record.targetCompletionDays > 0 else { throw OneStepBackupError.invalidTargetCompletionDays }
            if let startDayKey = record.startDayKey, LocalDay(rawValue: startDayKey) == nil {
                throw OneStepBackupError.invalidMilestoneStartDay
            }
        }

        var completionIDs: Set<UUID> = []
        var completionKeys: Set<String> = []
        for record in document.dailyCompletions {
            guard completionIDs.insert(record.id).inserted else { throw OneStepBackupError.duplicateDailyCompletionID }
            guard milestoneIDs.contains(record.goalID) else { throw OneStepBackupError.missingMilestoneForCompletion }
            guard LocalDay(rawValue: record.dayKey) != nil else { throw OneStepBackupError.invalidCompletionDay }
            let key = DailyCompletion.makeUniqueKey(goalID: record.goalID, dayKey: record.dayKey)
            guard completionKeys.insert(key).inserted else { throw OneStepBackupError.duplicateDailyCompletion }
        }
    }

    func deleteExistingRows() throws {
        for completion in try modelContext.fetch(FetchDescriptor<DailyCompletion>()) {
            modelContext.delete(completion)
        }
        for milestone in try modelContext.fetch(FetchDescriptor<MilestoneGoal>()) {
            modelContext.delete(milestone)
        }
        for finalGoal in try modelContext.fetch(FetchDescriptor<FinalGoal>()) {
            modelContext.delete(finalGoal)
        }
    }

    func snapshotExistingData() throws -> OneStepBackupDocument {
        try exportDocument()
    }

    func restoreFromSnapshot(_ snapshot: OneStepBackupDocument) {
        let completions = (try? modelContext.fetch(FetchDescriptor<DailyCompletion>())) ?? []
        for completion in completions { modelContext.delete(completion) }
        let milestones = (try? modelContext.fetch(FetchDescriptor<MilestoneGoal>())) ?? []
        for milestone in milestones { modelContext.delete(milestone) }
        let goals = (try? modelContext.fetch(FetchDescriptor<FinalGoal>())) ?? []
        for finalGoal in goals { modelContext.delete(finalGoal) }

        for record in snapshot.finalGoals {
            modelContext.insert(FinalGoal(
                id: record.id,
                title: record.title,
                goalDescription: record.goalDescription,
                targetCalendarDays: record.targetCalendarDays,
                startDayKey: record.startDayKey,
                sortOrder: record.sortOrder,
                archivedAt: record.archivedAt,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt
            ))
        }
        for record in snapshot.milestones {
            modelContext.insert(MilestoneGoal(
                id: record.id,
                title: record.title,
                targetCompletionDays: record.targetCompletionDays,
                finalGoalID: record.finalGoalID,
                sortOrder: record.sortOrder,
                isActive: record.isActive,
                startDayKey: record.startDayKey,
                completedAt: record.completedAt,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt
            ))
        }
        for record in snapshot.dailyCompletions {
            modelContext.insert(DailyCompletion(
                id: record.id,
                goalID: record.goalID,
                dayKey: record.dayKey,
                completedAt: record.completedAt
            ))
        }
    }

    func save() throws {
        do {
            try persist(modelContext)
        } catch {
            throw GoalRepositoryError.saveFailed(error.localizedDescription)
        }
    }
}
