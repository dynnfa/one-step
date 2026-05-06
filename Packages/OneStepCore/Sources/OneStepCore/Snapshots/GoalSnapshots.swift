import Foundation

public struct CreateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let startDay: LocalDay

    public init(title: String, goalDescription: String? = nil, targetCalendarDays: Int? = nil, startDay: LocalDay) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.startDay = startDay
    }
}

public struct UpdateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?

    public init(title: String, goalDescription: String? = nil, targetCalendarDays: Int? = nil) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
    }
}

public struct CreateMilestoneGoalInput: Equatable, Sendable {
    public let title: String
    public let targetCompletionDays: Int
    public let finalGoalID: UUID

    public init(title: String, targetCompletionDays: Int, finalGoalID: UUID) {
        self.title = title
        self.targetCompletionDays = targetCompletionDays
        self.finalGoalID = finalGoalID
    }
}

public struct UpdateMilestoneGoalInput: Equatable, Sendable {
    public let title: String
    public let targetCompletionDays: Int

    public init(title: String, targetCompletionDays: Int) {
        self.title = title
        self.targetCompletionDays = targetCompletionDays
    }
}

public struct FinalGoalListSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let completedMilestoneCount: Int
    public let totalMilestoneCount: Int
    public let currentMilestoneID: UUID?
    public let currentMilestoneTitle: String?
    public let remainingCalendarDays: Int?
    public let sortOrder: Int
    public let archivedAt: Date?

    public init(
        id: UUID,
        title: String,
        goalDescription: String?,
        targetCalendarDays: Int?,
        completedMilestoneCount: Int,
        totalMilestoneCount: Int,
        currentMilestoneID: UUID?,
        currentMilestoneTitle: String?,
        remainingCalendarDays: Int?,
        sortOrder: Int,
        archivedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.completedMilestoneCount = completedMilestoneCount
        self.totalMilestoneCount = totalMilestoneCount
        self.currentMilestoneID = currentMilestoneID
        self.currentMilestoneTitle = currentMilestoneTitle
        self.remainingCalendarDays = remainingCalendarDays
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
    }
}

public struct MilestoneGoalSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let targetCompletionDays: Int
    public let finalGoalID: UUID
    public let sortOrder: Int
    public let isCurrent: Bool
    public let completedDays: Int
    public let remainingDays: Int
    public let completionRate: Double
    public let isCompletedToday: Bool
    public let startDayKey: String?
    public let completedAt: Date?
    public let recentActivity: [RecentActivityDay]

    public init(
        id: UUID,
        title: String,
        targetCompletionDays: Int,
        finalGoalID: UUID,
        sortOrder: Int,
        isCurrent: Bool,
        completedDays: Int,
        remainingDays: Int,
        completionRate: Double,
        isCompletedToday: Bool,
        startDayKey: String?,
        completedAt: Date?,
        recentActivity: [RecentActivityDay]
    ) {
        self.id = id
        self.title = title
        self.targetCompletionDays = targetCompletionDays
        self.finalGoalID = finalGoalID
        self.sortOrder = sortOrder
        self.isCurrent = isCurrent
        self.completedDays = completedDays
        self.remainingDays = remainingDays
        self.completionRate = completionRate
        self.isCompletedToday = isCompletedToday
        self.startDayKey = startDayKey
        self.completedAt = completedAt
        self.recentActivity = recentActivity
    }
}

public struct WidgetMilestoneSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let parentFinalGoalTitle: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let isCompletedToday: Bool

    public init(
        id: UUID,
        title: String,
        parentFinalGoalTitle: String,
        targetCompletionDays: Int,
        completedDays: Int,
        isCompletedToday: Bool
    ) {
        self.id = id
        self.title = title
        self.parentFinalGoalTitle = parentFinalGoalTitle
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
