import Foundation

public enum GoalRepositoryError: Error, Equatable, LocalizedError {
    case goalNotFound
    case goalNotActive
    case invalidTitle
    case invalidDailyAction
    case invalidTargetCompletionDays
    case targetBelowCompletedCount
    case storeUnavailable
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .goalNotFound:
            return "Goal not found."
        case .goalNotActive:
            return "Goal is archived."
        case .invalidTitle:
            return "Goal title is required."
        case .invalidDailyAction:
            return "Daily action is required."
        case .invalidTargetCompletionDays:
            return "Target completion days must be greater than zero."
        case .targetBelowCompletedCount:
            return "Target completion days cannot be below completed days."
        case .storeUnavailable:
            return "Shared store is unavailable."
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
