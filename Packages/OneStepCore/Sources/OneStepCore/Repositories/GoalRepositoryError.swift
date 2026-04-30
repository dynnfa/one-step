import Foundation

public enum GoalRepositoryError: Error, Equatable, LocalizedError {
    case finalGoalNotFound
    case milestoneGoalNotFound
    case finalGoalNotActive
    case milestoneGoalNotActive
    case invalidTitle
    case invalidTargetCalendarDays
    case invalidTargetCompletionDays
    case targetBelowCompletedCount
    case notCurrentMilestone
    case milestonesIncomplete
    case storeUnavailable
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .finalGoalNotFound:
            return "Final goal not found."
        case .milestoneGoalNotFound:
            return "Milestone goal not found."
        case .finalGoalNotActive:
            return "Final goal is archived or completed."
        case .milestoneGoalNotActive:
            return "Milestone goal is archived or completed."
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
        case .milestonesIncomplete:
            return "All milestones must be completed before completing the final goal."
        case .storeUnavailable:
            return "Shared store is unavailable."
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
