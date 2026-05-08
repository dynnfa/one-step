import Foundation
import SwiftData

@MainActor
public struct FinalGoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> FinalGoalRepository {
        let container = try OneStepModelContainerFactory.sharedContainer(appGroupIdentifier: appGroupIdentifier)
        return FinalGoalRepository(modelContext: ModelContext(container))
    }

    public func createFinalGoal(_ input: CreateFinalGoalInput) throws -> UUID {
        let title = try validateTitle(input.title)
        if let calendarDays = input.targetCalendarDays {
            try validateTargetCalendarDays(calendarDays)
        }

        let goal = FinalGoal(
            title: title,
            goalDescription: input.goalDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            targetCalendarDays: input.targetCalendarDays,
            startDayKey: input.startDay.rawValue,
            sortOrder: try nextSortOrder()
        )
        modelContext.insert(goal)
        try save()
        return goal.id
    }

    public func updateFinalGoal(finalGoalID: UUID, input: UpdateFinalGoalInput) throws {
        let goal = try fetchFinalGoal(finalGoalID: finalGoalID)
        guard goal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        goal.title = try validateTitle(input.title)
        goal.goalDescription = input.goalDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if let calendarDays = input.targetCalendarDays {
            try validateTargetCalendarDays(calendarDays)
        }
        goal.targetCalendarDays = input.targetCalendarDays
        goal.updatedAt = Date()
        try save()
    }

    public func setFinalGoalArchived(finalGoalID: UUID, isArchived: Bool) throws {
        let goal = try fetchFinalGoal(finalGoalID: finalGoalID)
        goal.archivedAt = isArchived ? (goal.archivedAt ?? Date()) : nil
        goal.updatedAt = Date()
        try save()
    }

    public func deleteFinalGoal(finalGoalID: UUID) throws {
        let goal = try fetchFinalGoal(finalGoalID: finalGoalID)
        let milestones = try fetchMilestones(for: finalGoalID)
        for milestone in milestones {
            let completions = try fetchCompletions(goalID: milestone.id)
            for completion in completions {
                modelContext.delete(completion)
            }
            modelContext.delete(milestone)
        }
        modelContext.delete(goal)
        try save()
    }

    public func moveActiveFinalGoal(finalGoalID: UUID, toIndex: Int) throws {
        let goal = try fetchFinalGoal(finalGoalID: finalGoalID)
        guard goal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        var activeGoals = try fetchFinalGoals().filter(\.isActive)
        guard let currentIndex = activeGoals.firstIndex(where: { $0.id == finalGoalID }) else {
            throw GoalRepositoryError.finalGoalNotFound
        }

        let moved = activeGoals.remove(at: currentIndex)
        let boundedIndex = min(max(toIndex, 0), activeGoals.count)
        activeGoals.insert(moved, at: boundedIndex)

        for (index, activeGoal) in activeGoals.enumerated() {
            activeGoal.sortOrder = index
            activeGoal.updatedAt = Date()
        }
        try save()
    }

    public func finalGoalsForList() throws -> [FinalGoalListSnapshot] {
        try fetchFinalGoals().map { goal in
            try makeListSnapshot(goal: goal)
        }
    }

    public func createMilestoneGoal(_ input: CreateMilestoneGoalInput) throws -> UUID {
        let finalGoal = try fetchFinalGoal(finalGoalID: input.finalGoalID)
        guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        let title = try validateTitle(input.title)
        try validateTargetCompletionDays(input.targetCompletionDays)

        let sortOrder = try nextMilestoneSortOrder(for: input.finalGoalID)
        let milestone = MilestoneGoal(
            title: title,
            targetCompletionDays: input.targetCompletionDays,
            finalGoalID: input.finalGoalID,
            sortOrder: sortOrder
        )
        modelContext.insert(milestone)
        try save()
        return milestone.id
    }
}

@MainActor
private extension FinalGoalRepository {
    func fetchFinalGoals() throws -> [FinalGoal] {
        let descriptor = FetchDescriptor<FinalGoal>(
            sortBy: [
                SortDescriptor(\FinalGoal.sortOrder),
                SortDescriptor(\FinalGoal.createdAt)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFinalGoal(finalGoalID: UUID) throws -> FinalGoal {
        guard let goal = try fetchFinalGoalOrNil(finalGoalID: finalGoalID) else {
            throw GoalRepositoryError.finalGoalNotFound
        }
        return goal
    }

    func fetchFinalGoalOrNil(finalGoalID: UUID) throws -> FinalGoal? {
        let descriptor = FetchDescriptor<FinalGoal>(
            predicate: #Predicate { $0.id == finalGoalID }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchMilestones(for finalGoalID: UUID) throws -> [MilestoneGoal] {
        let descriptor = FetchDescriptor<MilestoneGoal>(
            predicate: #Predicate { $0.finalGoalID == finalGoalID },
            sortBy: [SortDescriptor(\MilestoneGoal.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompletions(goalID: UUID) throws -> [DailyCompletion] {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate { $0.goalID == goalID }
        )
        return try modelContext.fetch(descriptor)
    }

    func nextSortOrder() throws -> Int {
        let maxSortOrder = try fetchFinalGoals().map(\.sortOrder).max() ?? -1
        return maxSortOrder + 1
    }

    func nextMilestoneSortOrder(for finalGoalID: UUID) throws -> Int {
        let maxSortOrder = try fetchMilestones(for: finalGoalID).map(\.sortOrder).max() ?? -1
        return maxSortOrder + 1
    }

    func makeListSnapshot(goal: FinalGoal) throws -> FinalGoalListSnapshot {
        let milestones = try fetchMilestones(for: goal.id)
        let totalMilestoneCount = milestones.count
        let completedMilestoneCount = milestones.filter { $0.completedAt != nil }.count
        let activeMilestoneCount = milestones.filter { $0.isActive && $0.completedAt == nil }.count

        let remainingCalendarDays: Int? = goal.targetCalendarDays.map { limit in
            let startString = goal.startDayKey
            guard let startDate = dayDateFormatter.date(from: startString) else { return limit }
            let calendar = Calendar(identifier: .gregorian)
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            return max(limit - daysSinceStart, 0)
        }

        return FinalGoalListSnapshot(
            id: goal.id,
            title: goal.title,
            goalDescription: goal.goalDescription,
            targetCalendarDays: goal.targetCalendarDays,
            completedMilestoneCount: completedMilestoneCount,
            totalMilestoneCount: totalMilestoneCount,
            activeMilestoneCount: activeMilestoneCount,
            remainingCalendarDays: remainingCalendarDays,
            sortOrder: goal.sortOrder,
            archivedAt: goal.archivedAt
        )
    }

    func validateTitle(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GoalRepositoryError.invalidTitle }
        return trimmed
    }

    func validateTargetCalendarDays(_ days: Int) throws {
        guard days > 0 else { throw GoalRepositoryError.invalidTargetCalendarDays }
    }

    func validateTargetCompletionDays(_ days: Int) throws {
        guard days > 0 else { throw GoalRepositoryError.invalidTargetCompletionDays }
    }

    func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw GoalRepositoryError.saveFailed(error.localizedDescription)
        }
    }

    var dayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
