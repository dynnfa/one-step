import Foundation

public struct CreateGoalInput: Equatable, Sendable {
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let startDay: LocalDay

    public init(title: String, dailyAction: String, targetCompletionDays: Int, startDay: LocalDay) {
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.startDay = startDay
    }
}

public struct UpdateGoalInput: Equatable, Sendable {
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int

    public init(title: String, dailyAction: String, targetCompletionDays: Int) {
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
    }
}

public struct GoalListSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let remainingDays: Int
    public let completionRate: Double
    public let isCompletedToday: Bool
    public let sortOrder: Int
    public let archivedAt: Date?
    public let recentActivity: [RecentActivityDay]

    public init(
        id: UUID,
        title: String,
        dailyAction: String,
        targetCompletionDays: Int,
        completedDays: Int,
        remainingDays: Int,
        completionRate: Double,
        isCompletedToday: Bool,
        sortOrder: Int,
        archivedAt: Date?,
        recentActivity: [RecentActivityDay]
    ) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.completedDays = completedDays
        self.remainingDays = remainingDays
        self.completionRate = completionRate
        self.isCompletedToday = isCompletedToday
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.recentActivity = recentActivity
    }
}

public struct WidgetGoalSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let isCompletedToday: Bool

    public init(
        id: UUID,
        title: String,
        dailyAction: String,
        targetCompletionDays: Int,
        completedDays: Int,
        isCompletedToday: Bool
    ) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.completedDays = completedDays
        self.isCompletedToday = isCompletedToday
    }
}

public struct RecentActivityDay: Identifiable, Equatable, Sendable {
    public var id: String { day.rawValue }
    public let day: LocalDay
    public let isCompleted: Bool

    public init(day: LocalDay, isCompleted: Bool) {
        self.day = day
        self.isCompleted = isCompleted
    }
}
