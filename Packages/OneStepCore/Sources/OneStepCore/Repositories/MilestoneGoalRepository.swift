import Foundation
import SwiftData

@MainActor
public struct MilestoneGoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> MilestoneGoalRepository {
        let container = try OneStepModelContainerFactory.makeShared(appGroupIdentifier: appGroupIdentifier)
        return MilestoneGoalRepository(modelContext: ModelContext(container))
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

    public func updateMilestoneGoal(milestoneGoalID: UUID, input: UpdateMilestoneGoalInput) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        guard milestone.completedAt == nil else { throw GoalRepositoryError.notCurrentMilestone }

        let title = try validateTitle(input.title)
        try validateTargetCompletionDays(input.targetCompletionDays)
        let currentCompletedDays = try completedDays(for: milestoneGoalID)
        guard input.targetCompletionDays >= currentCompletedDays else {
            throw GoalRepositoryError.targetBelowCompletedCount
        }

        milestone.title = title
        milestone.targetCompletionDays = input.targetCompletionDays
        milestone.updatedAt = Date()
        try save()
    }

    public func deleteMilestoneGoal(milestoneGoalID: UUID) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        let completions = try fetchCompletions(goalID: milestoneGoalID)
        for completion in completions {
            modelContext.delete(completion)
        }
        modelContext.delete(milestone)
        try save()
    }

    public func completeToday(milestoneGoalID: UUID, day: LocalDay) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        guard milestone.completedAt == nil else { throw GoalRepositoryError.notCurrentMilestone }

        let finalGoal = try fetchFinalGoal(finalGoalID: milestone.finalGoalID)
        guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        let currentActive = try currentActiveMilestone(for: finalGoal.id)
        guard currentActive?.id == milestoneGoalID else {
            throw GoalRepositoryError.notCurrentMilestone
        }

        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
        guard try fetchCompletion(uniqueKey: uniqueKey) == nil else { return }

        if milestone.startDayKey == nil {
            milestone.startDayKey = day.rawValue
        }
        modelContext.insert(DailyCompletion(goalID: milestoneGoalID, dayKey: day.rawValue))
        milestone.updatedAt = Date()

        let newCompletedDays = try completedDays(for: milestoneGoalID)
        if newCompletedDays >= milestone.targetCompletionDays {
            milestone.completedAt = Date()
        }

        try save()
    }

    public func uncompleteToday(milestoneGoalID: UUID, day: LocalDay) throws {
        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
        if let completion = try fetchCompletion(uniqueKey: uniqueKey) {
            modelContext.delete(completion)
            if let milestone = try? fetchMilestoneGoal(milestoneGoalID: milestoneGoalID) {
                let remaining = try completedDays(for: milestoneGoalID) - 1
                if remaining < milestone.targetCompletionDays {
                    milestone.completedAt = nil
                }
                milestone.updatedAt = Date()
            }
            try save()
        }
    }

    public func milestonesForFinalGoal(finalGoalID: UUID, day: LocalDay) throws -> [MilestoneGoalSnapshot] {
        let currentActiveID = try currentActiveMilestone(for: finalGoalID)?.id
        let milestones = try fetchMilestones(for: finalGoalID)

        return milestones.map { milestone in
            let completedDays = (try? completedDays(for: milestone.id)) ?? 0
            let remainingDays = max(milestone.targetCompletionDays - completedDays, 0)
            let completionRate = milestone.targetCompletionDays > 0
                ? Double(completedDays) / Double(milestone.targetCompletionDays)
                : 0
            let isCompletedToday = (try? isCompleted(goalID: milestone.id, day: day)) ?? false

            return MilestoneGoalSnapshot(
                id: milestone.id,
                title: milestone.title,
                targetCompletionDays: milestone.targetCompletionDays,
                finalGoalID: milestone.finalGoalID,
                sortOrder: milestone.sortOrder,
                isCurrent: milestone.id == currentActiveID,
                completedDays: completedDays,
                remainingDays: remainingDays,
                completionRate: completionRate,
                isCompletedToday: isCompletedToday,
                startDayKey: milestone.startDayKey,
                completedAt: milestone.completedAt,
                recentActivity: (try? recentActivity(goalID: milestone.id, endingOn: day)) ?? []
            )
        }
    }

    public func activeMilestonesForWidget(limit: Int, day: LocalDay) throws -> [WidgetMilestoneSnapshot] {
        let boundedLimit = max(limit, 0)
        guard boundedLimit > 0 else { return [] }

        let activeFinalGoals = try fetchFinalGoals().filter(\.isActive)

        var snapshots: [WidgetMilestoneSnapshot] = []
        for finalGoal in activeFinalGoals {
            guard snapshots.count < boundedLimit else { break }
            guard let current = try currentActiveMilestone(for: finalGoal.id) else { continue }
            let completedDays = try completedDays(for: current.id)
            snapshots.append(WidgetMilestoneSnapshot(
                id: current.id,
                title: current.title,
                parentFinalGoalTitle: finalGoal.title,
                targetCompletionDays: current.targetCompletionDays,
                completedDays: completedDays,
                isCompletedToday: try isCompleted(goalID: current.id, day: day)
            ))
        }
        return snapshots
    }
}

@MainActor
private extension MilestoneGoalRepository {
    func fetchFinalGoals() throws -> [FinalGoal] {
        let descriptor = FetchDescriptor<FinalGoal>(
            sortBy: [SortDescriptor(\FinalGoal.sortOrder), SortDescriptor(\FinalGoal.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFinalGoal(finalGoalID: UUID) throws -> FinalGoal {
        let descriptor = FetchDescriptor<FinalGoal>(
            predicate: #Predicate { $0.id == finalGoalID }
        )
        guard let goal = try modelContext.fetch(descriptor).first else {
            throw GoalRepositoryError.finalGoalNotFound
        }
        return goal
    }

    func fetchMilestones(for finalGoalID: UUID) throws -> [MilestoneGoal] {
        let descriptor = FetchDescriptor<MilestoneGoal>(
            predicate: #Predicate { $0.finalGoalID == finalGoalID },
            sortBy: [SortDescriptor(\MilestoneGoal.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchMilestoneGoal(milestoneGoalID: UUID) throws -> MilestoneGoal {
        let descriptor = FetchDescriptor<MilestoneGoal>(
            predicate: #Predicate { $0.id == milestoneGoalID }
        )
        guard let milestone = try modelContext.fetch(descriptor).first else {
            throw GoalRepositoryError.milestoneGoalNotFound
        }
        return milestone
    }

    func currentActiveMilestone(for finalGoalID: UUID) throws -> MilestoneGoal? {
        let milestones = try fetchMilestones(for: finalGoalID)
        return milestones.first(where: { $0.isActive })
    }

    func fetchCompletions(goalID: UUID) throws -> [DailyCompletion] {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate { $0.goalID == goalID }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompletion(uniqueKey: String) throws -> DailyCompletion? {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate { $0.uniqueKey == uniqueKey }
        )
        return try modelContext.fetch(descriptor).first
    }

    func isCompleted(goalID: UUID, day: LocalDay) throws -> Bool {
        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: day.rawValue)
        return try fetchCompletion(uniqueKey: uniqueKey) != nil
    }

    func completedDays(for goalID: UUID) throws -> Int {
        try fetchCompletions(goalID: goalID).count
    }

    func nextMilestoneSortOrder(for finalGoalID: UUID) throws -> Int {
        (try fetchMilestones(for: finalGoalID).map(\.sortOrder).max() ?? -1) + 1
    }

    func recentActivity(goalID: UUID, endingOn day: LocalDay) throws -> [RecentActivityDay] {
        let completedDayKeys = Set(try fetchCompletions(goalID: goalID).map(\.dayKey))
        let days = lastThirtyDays(endingOn: day)
        return days.map { activityDay in
            RecentActivityDay(day: activityDay, isCompleted: completedDayKeys.contains(activityDay.rawValue))
        }
    }

    func lastThirtyDays(endingOn day: LocalDay) -> [LocalDay] {
        guard let endDate = dayDateFormatter.date(from: day.rawValue) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return (0..<30).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else {
                return nil
            }
            return LocalDay(date: date, calendar: calendar)
        }
    }

    func validateTitle(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GoalRepositoryError.invalidTitle }
        return trimmed
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
