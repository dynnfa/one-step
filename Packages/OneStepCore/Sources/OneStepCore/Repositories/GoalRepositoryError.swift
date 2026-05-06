import Foundation

public enum GoalRepositoryError: Error, Equatable, LocalizedError {
    case finalGoalNotFound
    case milestoneGoalNotFound
    case finalGoalNotActive
    case invalidTitle
    case invalidTargetCalendarDays
    case invalidTargetCompletionDays
    case targetBelowCompletedCount
    case notCurrentMilestone
    case storeUnavailable
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .finalGoalNotFound:
            return "Final goal not found."
        case .milestoneGoalNotFound:
            return "Milestone goal not found."
        case .finalGoalNotActive:
            return "Final goal is archived."
        case .invalidTitle:
            return "Title is required."
        case .invalidTargetCalendarDays:
            return "Calendar day limit must be greater than zero."
        case .invalidTargetCompletionDays:
            return "Target completion days must be greater than zero."
        case .targetBelowCompletedCount:
            return "Target completion days cannot be below completed days."
        case .notCurrentMilestone:
            return "Only the current active milestone can receive check-ins."
        case .storeUnavailable:
            return "Shared store is unavailable."
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
