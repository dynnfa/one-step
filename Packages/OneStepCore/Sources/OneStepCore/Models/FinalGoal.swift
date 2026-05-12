import Foundation
import SwiftData

@Model
public final class FinalGoal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var goalDescription: String?
    public var targetCalendarDays: Int?
    public var colorThemeID: String = FinalGoalColorTheme.defaultTheme.id
    public var customColorHex: String?
    public var startDayKey: String
    public var sortOrder: Int
    public var archivedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String? = nil,
        targetCalendarDays: Int? = nil,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil,
        startDayKey: String,
        sortOrder: Int,
        archivedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.colorThemeID = colorThemeID
        self.customColorHex = customColorHex
        self.startDayKey = startDayKey
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { archivedAt == nil }
}
