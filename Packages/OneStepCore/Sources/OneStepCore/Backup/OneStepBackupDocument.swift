import Foundation

public struct OneStepBackupDocument: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let exportedAt: Date
    public let finalGoals: [FinalGoalRecord]
    public let milestones: [MilestoneGoalRecord]
    public let dailyCompletions: [DailyCompletionRecord]

    public init(
        schemaVersion: Int = OneStepBackupDocument.currentSchemaVersion,
        exportedAt: Date,
        finalGoals: [FinalGoalRecord],
        milestones: [MilestoneGoalRecord],
        dailyCompletions: [DailyCompletionRecord]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.finalGoals = finalGoals
        self.milestones = milestones
        self.dailyCompletions = dailyCompletions
    }

    public struct FinalGoalRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let goalDescription: String?
        public let targetCalendarDays: Int?
        public let startDayKey: String
        public let sortOrder: Int
        public let archivedAt: Date?
        public let createdAt: Date
        public let updatedAt: Date

        public init(
            id: UUID,
            title: String,
            goalDescription: String?,
            targetCalendarDays: Int?,
            startDayKey: String,
            sortOrder: Int,
            archivedAt: Date?,
            createdAt: Date,
            updatedAt: Date
        ) {
            self.id = id
            self.title = title
            self.goalDescription = goalDescription
            self.targetCalendarDays = targetCalendarDays
            self.startDayKey = startDayKey
            self.sortOrder = sortOrder
            self.archivedAt = archivedAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    public struct MilestoneGoalRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let targetCompletionDays: Int
        public let finalGoalID: UUID
        public let sortOrder: Int
        public let isActive: Bool
        public let startDayKey: String?
        public let completedAt: Date?
        public let createdAt: Date
        public let updatedAt: Date

        public init(
            id: UUID,
            title: String,
            targetCompletionDays: Int,
            finalGoalID: UUID,
            sortOrder: Int,
            isActive: Bool,
            startDayKey: String?,
            completedAt: Date?,
            createdAt: Date,
            updatedAt: Date
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

    public struct DailyCompletionRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let goalID: UUID
        public let dayKey: String
        public let completedAt: Date

        public init(id: UUID, goalID: UUID, dayKey: String, completedAt: Date) {
            self.id = id
            self.goalID = goalID
            self.dayKey = dayKey
            self.completedAt = completedAt
        }
    }
}
