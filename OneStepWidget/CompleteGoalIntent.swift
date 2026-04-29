import AppIntents
import OneStepCore
import WidgetKit

struct CompleteGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Goal"

    @Parameter(title: "Goal ID")
    var goalID: String

    init() {}

    init(goalID: UUID) {
        self.goalID = goalID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Widget tap -> AppIntent -> GoalRepository -> SwiftData/App Group -> Widget reload
        guard let id = UUID(uuidString: goalID) else {
            OneStepLog.appIntent.error("Invalid goal ID: \(goalID)")
            return .result()
        }

        do {
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            try repository.completeToday(goalID: id, day: .today)
            WidgetCenter.shared.reloadTimelines(ofKind: OneStepWidget.kind)
        } catch GoalRepositoryError.goalNotFound {
            OneStepLog.appIntent.error("Stale widget tap ignored because goal was missing: \(goalID)")
        } catch GoalRepositoryError.goalNotActive {
            OneStepLog.appIntent.error("Stale widget tap ignored because goal was archived: \(goalID)")
        } catch {
            OneStepLog.appIntent.error("CompleteGoalIntent failed: \(error.localizedDescription)")
        }

        return .result()
    }
}
