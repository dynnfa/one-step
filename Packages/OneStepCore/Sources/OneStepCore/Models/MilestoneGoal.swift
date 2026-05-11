import Foundation
import SwiftData

@Model
public final class MilestoneGoal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var targetCompletionDays: Int
    public var finalGoalID: UUID
    public var sortOrder: Int
    public var isActive: Bool
    public var startDayKey: String?
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        targetCompletionDays: Int,
        finalGoalID: UUID,
        sortOrder: Int,
        isActive: Bool = false,
        startDayKey: String? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetCompletionDays = targetCompletionDays
        self.finalGoalID = finalGoalID
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.startDayKey = startDayKey
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
