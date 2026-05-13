import Foundation
import SwiftData

@MainActor
public struct MilestoneGoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> MilestoneGoalRepository {
        let container = try OneStepModelContainerFactory.sharedContainer(appGroupIdentifier: appGroupIdentifier)
        return MilestoneGoalRepository(modelContext: ModelContext(container))
    }

    public func backfillLegacyActiveMilestonesIfNeeded() throws {
        var didChange = false
        let activeFinalGoals = try fetchFinalGoals().filter(\.isActive)
        for finalGoal in activeFinalGoals {
            let milestones = try fetchMilestones(for: finalGoal.id)
            let incompleteMilestones = milestones.filter { $0.completedAt == nil }

            for milestone in milestones where milestone.completedAt != nil && milestone.isActive {
                milestone.isActive = false
                milestone.updatedAt = Date()
                didChange = true
            }

            if !incompleteMilestones.contains(where: \.isActive),
               let firstIncomplete = incompleteMilestones.first {
                firstIncomplete.isActive = true
                firstIncomplete.updatedAt = Date()
                didChange = true
            }
        }

        if didChange {
            try save()
        }
    }

    public func createMilestoneGoal(_ input: CreateMilestoneGoalInput) throws -> UUID {
        let finalGoal = try fetchFinalGoal(finalGoalID: input.finalGoalID)
        guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        let title = try validateTitle(input.title)
        try validateTargetCompletionTimes(input.targetCompletionTimes)

        let sortOrder = try nextMilestoneSortOrder(for: input.finalGoalID)
        let milestone = MilestoneGoal(
            title: title,
            targetCompletionTimes: input.targetCompletionTimes,
            finalGoalID: input.finalGoalID,
            sortOrder: sortOrder
        )
        modelContext.insert(milestone)
        try save()
        return milestone.id
    }

    public func updateMilestoneGoal(milestoneGoalID: UUID, input: UpdateMilestoneGoalInput) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        guard milestone.completedAt == nil else { throw GoalRepositoryError.milestoneNotActive }

        let title = try validateTitle(input.title)
        try validateTargetCompletionTimes(input.targetCompletionTimes)
        let currentCompletedDays = try completedDays(for: milestoneGoalID)
        if let targetCompletionTimes = input.targetCompletionTimes,
           targetCompletionTimes < currentCompletedDays {
            throw GoalRepositoryError.targetBelowCompletedCount
        }

        milestone.title = title
        milestone.targetCompletionTimes = input.targetCompletionTimes
        if let targetCompletionTimes = input.targetCompletionTimes,
           currentCompletedDays >= targetCompletionTimes {
            milestone.completedAt = Date()
            milestone.isActive = false
        }
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
        let finalGoal = try fetchFinalGoal(finalGoalID: milestone.finalGoalID)
        guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }
        guard milestone.completedAt == nil, milestone.isActive
        else { throw GoalRepositoryError.milestoneNotActive }

        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
        guard try fetchCompletion(uniqueKey: uniqueKey) == nil else { return }

        if milestone.startDayKey == nil {
            milestone.startDayKey = day.rawValue
        }
        modelContext.insert(DailyCompletion(goalID: milestoneGoalID, dayKey: day.rawValue))
        milestone.updatedAt = Date()

        let newCompletedDays = try completedDays(for: milestoneGoalID)
        if let targetCompletionTimes = milestone.targetCompletionTimes,
           newCompletedDays >= targetCompletionTimes {
            milestone.completedAt = Date()
            milestone.isActive = false
        }

        try save()
    }

    public func uncompleteToday(milestoneGoalID: UUID, day: LocalDay) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        let finalGoal = try fetchFinalGoal(finalGoalID: milestone.finalGoalID)
        guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }

        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
        if let completion = try fetchCompletion(uniqueKey: uniqueKey) {
            modelContext.delete(completion)
            let remaining = try completedDays(for: milestoneGoalID) - 1
            if shouldReopenMilestone(remainingCompletionCount: remaining, targetCompletionTimes: milestone.targetCompletionTimes) {
                milestone.completedAt = nil
                milestone.isActive = true
            }
            milestone.updatedAt = Date()
            try save()
        }
    }

    public func setMilestoneActive(milestoneGoalID: UUID, isActive: Bool) throws {
        let milestone = try fetchMilestoneGoal(milestoneGoalID: milestoneGoalID)
        let finalGoal = try fetchFinalGoal(finalGoalID: milestone.finalGoalID)
        if isActive {
            guard finalGoal.isActive else { throw GoalRepositoryError.finalGoalNotActive }
            guard milestone.completedAt == nil else { throw GoalRepositoryError.milestoneNotActive }
        }

        milestone.isActive = isActive
        milestone.updatedAt = Date()
        try save()
    }

    public func milestonesForFinalGoal(
        finalGoalID: UUID,
        day: LocalDay,
        recentActivityDayLimit: Int = 30
    ) throws -> [MilestoneGoalSnapshot] {
        let milestones = try fetchMilestones(for: finalGoalID)

        return try milestones.map { milestone in
            let completedDays = try completedDays(for: milestone.id)
            let isCompletedToday = try isCompleted(goalID: milestone.id, day: day)
            let requestedActivityLimit = max(recentActivityDayLimit, 0)
            let activityLimit: Int
            if let targetCompletionTimes = milestone.targetCompletionTimes {
                activityLimit = min(requestedActivityLimit, targetCompletionTimes)
            } else {
                activityLimit = requestedActivityLimit
            }

            return MilestoneGoalSnapshot(
                id: milestone.id,
                title: milestone.title,
                targetCompletionTimes: milestone.targetCompletionTimes,
                finalGoalID: milestone.finalGoalID,
                sortOrder: milestone.sortOrder,
                isActive: milestone.isActive && milestone.completedAt == nil,
                completedDays: completedDays,
                isCompletedToday: isCompletedToday,
                startDayKey: milestone.startDayKey,
                completedAt: milestone.completedAt,
                recentActivity: try recentActivity(goalID: milestone.id, endingOn: day, dayCount: activityLimit)
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
            let activeMilestones = try fetchMilestones(for: finalGoal.id)
                .filter { $0.isActive && $0.completedAt == nil }
            for milestone in activeMilestones {
                guard snapshots.count < boundedLimit else { break }
                let completedDays = try completedDays(for: milestone.id)
                snapshots.append(WidgetMilestoneSnapshot(
                    id: milestone.id,
                    title: milestone.title,
                    parentFinalGoalTitle: finalGoal.title,
                    colorHex: FinalGoalColorTheme.resolvedHex(
                        themeID: finalGoal.colorThemeID,
                        customColorHex: finalGoal.customColorHex
                    ),
                    targetCompletionTimes: milestone.targetCompletionTimes,
                    completedDays: completedDays,
                    isCompletedToday: try isCompleted(goalID: milestone.id, day: day)
                ))
            }
        }
        return snapshots
    }
}

@MainActor
extension MilestoneGoalRepository {
    func fetchCompletions(
        goalID: UUID,
        fromDayKey: String,
        throughDayKey: String
    ) throws -> [DailyCompletion] {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate {
                $0.goalID == goalID &&
                    $0.dayKey >= fromDayKey &&
                    $0.dayKey <= throughDayKey
            },
            sortBy: [SortDescriptor(\DailyCompletion.dayKey)]
        )
        return try modelContext.fetch(descriptor)
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

    func shouldReopenMilestone(remainingCompletionCount: Int, targetCompletionTimes: Int?) -> Bool {
        guard let targetCompletionTimes else { return true }
        return remainingCompletionCount < targetCompletionTimes
    }

    func nextMilestoneSortOrder(for finalGoalID: UUID) throws -> Int {
        (try fetchMilestones(for: finalGoalID).map(\.sortOrder).max() ?? -1) + 1
    }

    func recentActivity(goalID: UUID, endingOn day: LocalDay, dayCount: Int) throws -> [RecentActivityDay] {
        let days = recentDays(endingOn: day, count: dayCount)
        guard let firstDay = days.first, let lastDay = days.last else { return [] }
        let completedDayKeys = Set(try fetchCompletions(
            goalID: goalID,
            fromDayKey: firstDay.rawValue,
            throughDayKey: lastDay.rawValue
        ).map(\.dayKey))
        return days.map { activityDay in
            RecentActivityDay(day: activityDay, isCompleted: completedDayKeys.contains(activityDay.rawValue))
        }
    }

    func recentDays(endingOn day: LocalDay, count: Int) -> [LocalDay] {
        let boundedCount = max(count, 0)
        guard boundedCount > 0 else { return [] }
        guard let endDate = dayDateFormatter.date(from: day.rawValue) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return (0..<boundedCount).reversed().compactMap { offset in
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

    func validateTargetCompletionTimes(_ times: Int?) throws {
        guard let times else { return }
        guard times > 0 else { throw GoalRepositoryError.invalidTargetCompletionDays }
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
