import Foundation
import SwiftData

@Model
public final class DailyCompletion {
    @Attribute(.unique) public var uniqueKey: String
    public var id: UUID
    // Stores MilestoneGoal.id (semantically changed from old Goal.id)
    public var goalID: UUID
    public var dayKey: String
    public var completedAt: Date

    public init(id: UUID = UUID(), goalID: UUID, dayKey: String, completedAt: Date = Date()) {
        self.id = id
        self.goalID = goalID
        self.dayKey = dayKey
        self.completedAt = completedAt
        self.uniqueKey = DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: dayKey)
    }

    public static func makeUniqueKey(goalID: UUID, dayKey: String) -> String {
        "\(goalID.uuidString)#\(dayKey)"
    }
}
