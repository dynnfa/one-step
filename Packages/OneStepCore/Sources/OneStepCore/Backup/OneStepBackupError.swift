import Foundation

public enum OneStepBackupError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case duplicateFinalGoalID
    case duplicateMilestoneGoalID
    case duplicateDailyCompletionID
    case duplicateDailyCompletion
    case invalidFinalGoalTitle
    case invalidMilestoneTitle
    case invalidFinalGoalStartDay
    case invalidMilestoneStartDay
    case invalidCompletionDay
    case invalidTargetCalendarDays
    case invalidTargetCompletionDays
    case missingFinalGoalForMilestone
    case missingMilestoneForCompletion
    case decodeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "This backup uses schema version \(version), which this version of One Step cannot import."
        case .duplicateFinalGoalID:
            return "The backup contains duplicate final goal IDs."
        case .duplicateMilestoneGoalID:
            return "The backup contains duplicate milestone IDs."
        case .duplicateDailyCompletionID:
            return "The backup contains duplicate daily completion IDs."
        case .duplicateDailyCompletion:
            return "The backup contains duplicate daily completions for the same milestone and day."
        case .invalidFinalGoalTitle:
            return "A final goal in the backup has an empty title."
        case .invalidMilestoneTitle:
            return "A milestone in the backup has an empty title."
        case .invalidFinalGoalStartDay:
            return "A final goal in the backup has an invalid start day."
        case .invalidMilestoneStartDay:
            return "A milestone in the backup has an invalid start day."
        case .invalidCompletionDay:
            return "A daily completion in the backup has an invalid day."
        case .invalidTargetCalendarDays:
            return "A final goal in the backup has a calendar day limit below one."
        case .invalidTargetCompletionDays:
            return "A milestone in the backup has a target completion count below one."
        case .missingFinalGoalForMilestone:
            return "A milestone in the backup points to a missing final goal."
        case .missingMilestoneForCompletion:
            return "A daily completion in the backup points to a missing milestone."
        case .decodeFailed(let message):
            return "The backup file could not be read: \(message)"
        }
    }
}
