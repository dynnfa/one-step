import Foundation
import SwiftData

@MainActor
public struct GoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> GoalRepository {
        let container = try OneStepModelContainerFactory.makeShared(appGroupIdentifier: appGroupIdentifier)
        return GoalRepository(modelContext: ModelContext(container))
    }

    public func createGoal(_ input: CreateGoalInput) throws -> UUID {
        let title = try validateTitle(input.title)
        let dailyAction = try validateDailyAction(input.dailyAction)
        try validateTargetCompletionDays(input.targetCompletionDays)

        let goal = Goal(
            title: title,
            dailyAction: dailyAction,
            targetCompletionDays: input.targetCompletionDays,
            startDayKey: input.startDay.rawValue,
            sortOrder: try nextSortOrder()
        )
        modelContext.insert(goal)
        try save()
        return goal.id
    }

    public func updateGoal(goalID: UUID, input: UpdateGoalInput) throws {
        let goal = try fetchGoal(goalID: goalID)
        guard goal.isActive else { throw GoalRepositoryError.goalNotActive }

        let title = try validateTitle(input.title)
        let dailyAction = try validateDailyAction(input.dailyAction)
        try validateTargetCompletionDays(input.targetCompletionDays)
        guard input.targetCompletionDays >= (try completedDays(for: goalID)) else {
            throw GoalRepositoryError.targetBelowCompletedCount
        }

        goal.title = title
        goal.dailyAction = dailyAction
        goal.targetCompletionDays = input.targetCompletionDays
        goal.updatedAt = Date()
        try save()
    }

    public func archiveGoal(goalID: UUID, archivedAt: Date) throws {
        let goal = try fetchGoal(goalID: goalID)
        goal.archivedAt = archivedAt
        goal.updatedAt = Date()
        try save()
    }

    public func moveActiveGoal(goalID: UUID, toIndex: Int) throws {
        let goal = try fetchGoal(goalID: goalID)
        guard goal.isActive else { throw GoalRepositoryError.goalNotActive }

        var activeGoals = try fetchGoals().filter(\.isActive)
        guard let currentIndex = activeGoals.firstIndex(where: { $0.id == goalID }) else {
            throw GoalRepositoryError.goalNotFound
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

    public func completeToday(goalID: UUID, day: LocalDay) throws {
        let goal = try fetchGoal(goalID: goalID)
        guard goal.isActive else { throw GoalRepositoryError.goalNotActive }

        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: day.rawValue)
        guard try fetchCompletion(uniqueKey: uniqueKey) == nil else { return }

        modelContext.insert(DailyCompletion(goalID: goalID, dayKey: day.rawValue))
        goal.updatedAt = Date()
        try save()
    }

    public func uncompleteToday(goalID: UUID, day: LocalDay) throws {
        let uniqueKey = DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: day.rawValue)
        if let completion = try fetchCompletion(uniqueKey: uniqueKey) {
            modelContext.delete(completion)
            if let goal = try? fetchGoal(goalID: goalID) {
                goal.updatedAt = Date()
            }
            try save()
        }
    }

    public func goalsForList(day: LocalDay) throws -> [GoalListSnapshot] {
        try fetchGoals().map { goal in
            try makeListSnapshot(goal: goal, day: day)
        }
    }

    public func activeGoalsForWidget(limit: Int, day: LocalDay) throws -> [WidgetGoalSnapshot] {
        let boundedLimit = max(limit, 0)
        guard boundedLimit > 0 else { return [] }

        return try fetchGoals()
            .filter(\.isActive)
            .prefix(boundedLimit)
            .map { goal in
                let completedDays = try completedDays(for: goal.id)
                return WidgetGoalSnapshot(
                    id: goal.id,
                    title: goal.title,
                    dailyAction: goal.dailyAction,
                    targetCompletionDays: goal.targetCompletionDays,
                    completedDays: completedDays,
                    isCompletedToday: try isCompleted(goalID: goal.id, day: day)
                )
            }
    }
}

@MainActor
private extension GoalRepository {
    func fetchGoals() throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            sortBy: [
                SortDescriptor(\Goal.sortOrder),
                SortDescriptor(\Goal.createdAt)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchGoal(goalID: UUID) throws -> Goal {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { goal in
                goal.id == goalID
            }
        )
        guard let goal = try modelContext.fetch(descriptor).first else {
            throw GoalRepositoryError.goalNotFound
        }
        return goal
    }

    func fetchCompletions(goalID: UUID) throws -> [DailyCompletion] {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate { completion in
                completion.goalID == goalID
            },
            sortBy: [SortDescriptor(\DailyCompletion.dayKey)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompletion(uniqueKey: String) throws -> DailyCompletion? {
        let descriptor = FetchDescriptor<DailyCompletion>(
            predicate: #Predicate { completion in
                completion.uniqueKey == uniqueKey
            }
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

    func nextSortOrder() throws -> Int {
        let maxSortOrder = try fetchGoals().map(\.sortOrder).max() ?? -1
        return maxSortOrder + 1
    }

    func makeListSnapshot(goal: Goal, day: LocalDay) throws -> GoalListSnapshot {
        let completedDays = try completedDays(for: goal.id)
        let remainingDays = max(goal.targetCompletionDays - completedDays, 0)
        let completionRate = goal.targetCompletionDays > 0
            ? Double(completedDays) / Double(goal.targetCompletionDays)
            : 0

        return GoalListSnapshot(
            id: goal.id,
            title: goal.title,
            dailyAction: goal.dailyAction,
            targetCompletionDays: goal.targetCompletionDays,
            completedDays: completedDays,
            remainingDays: remainingDays,
            completionRate: completionRate,
            isCompletedToday: try isCompleted(goalID: goal.id, day: day),
            sortOrder: goal.sortOrder,
            archivedAt: goal.archivedAt,
            recentActivity: try recentActivity(goalID: goal.id, endingOn: day)
        )
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

    func validateDailyAction(_ dailyAction: String) throws -> String {
        let trimmed = dailyAction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GoalRepositoryError.invalidDailyAction }
        return trimmed
    }

    func validateTargetCompletionDays(_ targetCompletionDays: Int) throws {
        guard targetCompletionDays > 0 else { throw GoalRepositoryError.invalidTargetCompletionDays }
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
