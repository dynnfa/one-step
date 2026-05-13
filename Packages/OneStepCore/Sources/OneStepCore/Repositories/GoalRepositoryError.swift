import Foundation

public enum GoalRepositoryError: Error, Equatable, LocalizedError {
    case finalGoalNotFound
    case milestoneGoalNotFound
    case finalGoalNotActive
    case invalidTitle
    case invalidTargetCalendarDays
    case invalidTargetCompletionDays
    case targetBelowCompletedCount
    case milestoneNotActive
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
            return "Target completion times must be greater than zero."
        case .targetBelowCompletedCount:
            return "Target completion times cannot be below completed times."
        case .milestoneNotActive:
            return "Milestone is not current or is already complete."
        case .storeUnavailable:
            return "Shared store is unavailable."
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
