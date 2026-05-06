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
        guard let id = UUID(uuidString: goalID) else {
            OneStepLog.appIntent.error("Invalid milestone ID: \(goalID)")
            return .result()
        }

        do {
            let repository = try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            try repository.completeToday(milestoneGoalID: id, day: .today)
            WidgetCenter.shared.reloadTimelines(ofKind: OneStepWidget.kind)
        } catch GoalRepositoryError.milestoneGoalNotFound {
            OneStepLog.appIntent.error("Stale widget tap ignored because milestone was missing: \(goalID)")
        } catch GoalRepositoryError.milestoneNotActive {
            OneStepLog.appIntent.error("Stale widget tap ignored because milestone was not active: \(goalID)")
        } catch {
            OneStepLog.appIntent.error("CompleteGoalIntent failed: \(error.localizedDescription)")
        }

        return .result()
    }
}
