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
        public let colorThemeID: String
        public let customColorHex: String?
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
            colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
            customColorHex: String? = nil,
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
            self.colorThemeID = colorThemeID
            self.customColorHex = customColorHex
            self.startDayKey = startDayKey
            self.sortOrder = sortOrder
            self.archivedAt = archivedAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case goalDescription
            case targetCalendarDays
            case colorThemeID
            case customColorHex
            case startDayKey
            case sortOrder
            case archivedAt
            case createdAt
            case updatedAt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            goalDescription = try container.decodeIfPresent(String.self, forKey: .goalDescription)
            targetCalendarDays = try container.decodeIfPresent(Int.self, forKey: .targetCalendarDays)
            let decodedThemeID = try container.decodeIfPresent(String.self, forKey: .colorThemeID)
            let decodedCustomColorHex = try container.decodeIfPresent(String.self, forKey: .customColorHex)
            let colorSelection = FinalGoalColorTheme.sanitizedSelection(
                themeID: decodedThemeID,
                customColorHex: decodedCustomColorHex
            )
            colorThemeID = colorSelection.themeID
            customColorHex = colorSelection.customColorHex
            startDayKey = try container.decode(String.self, forKey: .startDayKey)
            sortOrder = try container.decode(Int.self, forKey: .sortOrder)
            archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
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
