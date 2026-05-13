import Foundation

public struct CreateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let colorThemeID: String
    public let customColorHex: String?
    public let startDay: LocalDay

    public init(
        title: String,
        goalDescription: String? = nil,
        targetCalendarDays: Int? = nil,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil,
        startDay: LocalDay
    ) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        let colorSelection = FinalGoalColorTheme.sanitizedSelection(
            themeID: colorThemeID,
            customColorHex: customColorHex
        )
        self.colorThemeID = colorSelection.themeID
        self.customColorHex = colorSelection.customColorHex
        self.startDay = startDay
    }
}

public struct UpdateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let colorThemeID: String
    public let customColorHex: String?

    public init(
        title: String,
        goalDescription: String? = nil,
        targetCalendarDays: Int? = nil,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil
    ) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        let colorSelection = FinalGoalColorTheme.sanitizedSelection(
            themeID: colorThemeID,
            customColorHex: customColorHex
        )
        self.colorThemeID = colorSelection.themeID
        self.customColorHex = colorSelection.customColorHex
    }
}

public struct CreateMilestoneGoalInput: Equatable, Sendable {
    public let title: String
    public let targetCompletionTimes: Int?
    public let finalGoalID: UUID

    public init(title: String, targetCompletionTimes: Int?, finalGoalID: UUID) {
        self.title = title
        self.targetCompletionTimes = targetCompletionTimes
        self.finalGoalID = finalGoalID
    }
}

public struct UpdateMilestoneGoalInput: Equatable, Sendable {
    public let title: String
    public let targetCompletionTimes: Int?

    public init(title: String, targetCompletionTimes: Int?) {
        self.title = title
        self.targetCompletionTimes = targetCompletionTimes
    }
}

public struct FinalGoalListSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let colorThemeID: String
    public let customColorHex: String?
    public let colorHex: String
    public let completedMilestoneCount: Int
    public let totalMilestoneCount: Int
    public let activeMilestoneCount: Int
    public let remainingCalendarDays: Int?
    public let sortOrder: Int
    public let archivedAt: Date?

    public init(
        id: UUID,
        title: String,
        goalDescription: String?,
        targetCalendarDays: Int?,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil,
        colorHex: String? = nil,
        completedMilestoneCount: Int,
        totalMilestoneCount: Int,
        activeMilestoneCount: Int,
        remainingCalendarDays: Int?,
        sortOrder: Int,
        archivedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        let colorSelection = FinalGoalColorTheme.sanitizedSelection(
            themeID: colorThemeID,
            customColorHex: customColorHex
        )
        self.colorThemeID = colorSelection.themeID
        self.customColorHex = colorSelection.customColorHex
        self.colorHex = FinalGoalColorTheme.normalizedHex(colorHex) ?? colorSelection.colorHex
        self.completedMilestoneCount = completedMilestoneCount
        self.totalMilestoneCount = totalMilestoneCount
        self.activeMilestoneCount = activeMilestoneCount
        self.remainingCalendarDays = remainingCalendarDays
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
    }
}

public struct MilestoneGoalSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let targetCompletionTimes: Int?
    public let finalGoalID: UUID
    public let sortOrder: Int
    public let isActive: Bool
    public let completedDays: Int
    public let isCompletedToday: Bool
    public let startDayKey: String?
    public let completedAt: Date?
    public let recentActivity: [RecentActivityDay]

    public init(
        id: UUID,
        title: String,
        targetCompletionTimes: Int?,
        finalGoalID: UUID,
        sortOrder: Int,
        isActive: Bool,
        completedDays: Int,
        isCompletedToday: Bool,
        startDayKey: String?,
        completedAt: Date?,
        recentActivity: [RecentActivityDay]
    ) {
        self.id = id
        self.title = title
        self.targetCompletionTimes = targetCompletionTimes
        self.finalGoalID = finalGoalID
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.completedDays = completedDays
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
    public let colorHex: String
    public let targetCompletionTimes: Int?
    public let completedDays: Int
    public let isCompletedToday: Bool

    public init(
        id: UUID,
        title: String,
        parentFinalGoalTitle: String,
        colorHex: String = FinalGoalColorTheme.defaultTheme.hex,
        targetCompletionTimes: Int?,
        completedDays: Int,
        isCompletedToday: Bool
    ) {
        self.id = id
        self.title = title
        self.parentFinalGoalTitle = parentFinalGoalTitle
        self.colorHex = FinalGoalColorTheme.normalizedHex(colorHex) ?? FinalGoalColorTheme.defaultTheme.hex
        self.targetCompletionTimes = targetCompletionTimes
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
