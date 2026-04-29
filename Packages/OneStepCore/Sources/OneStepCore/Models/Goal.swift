import Foundation
import SwiftData

@Model
public final class Goal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var dailyAction: String
    public var targetCompletionDays: Int
    public var startDayKey: String
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        dailyAction: String,
        targetCompletionDays: Int,
        startDayKey: String,
        sortOrder: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.startDayKey = startDayKey
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }

    public var isActive: Bool { archivedAt == nil }
}
