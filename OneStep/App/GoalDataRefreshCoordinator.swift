import OneStepCore
import SwiftUI

@MainActor
enum GoalDataRefreshCoordinator {
    static func connect(finalGoalStore: FinalGoalStore, milestoneStore: MilestoneGoalStore) {
        milestoneStore.onMilestonesChanged = { [weak finalGoalStore, weak milestoneStore] in
            guard let finalGoalStore, let milestoneStore else { return }
            refreshAfterGoalDataChange(finalGoalStore: finalGoalStore, milestoneStore: milestoneStore)
        }
    }

    static func refreshAfterGoalDataChange(
        finalGoalStore: FinalGoalStore,
        milestoneStore: MilestoneGoalStore,
        day: LocalDay = .today
    ) {
        finalGoalStore.refresh()
        guard let selectedID = finalGoalStore.selectedFinalGoalID else { return }

        if finalGoalStore.finalGoals.contains(where: { $0.id == selectedID }) {
            milestoneStore.refresh(finalGoalID: selectedID, day: day)
        } else {
            finalGoalStore.select(nil)
            milestoneStore.milestones = []
        }
    }
}

@MainActor
final class GoalDataExternalRefreshScheduler {
    private var pendingRefreshTask: Task<Void, Never>?

    func controlActiveStateDidChange(
        _ state: ControlActiveState,
        finalGoalStore: FinalGoalStore,
        milestoneStore: MilestoneGoalStore,
        day: LocalDay = .today,
        inactiveDelay: Duration = .milliseconds(750)
    ) {
        pendingRefreshTask?.cancel()

        switch state {
        case .key:
            GoalDataRefreshCoordinator.refreshAfterGoalDataChange(
                finalGoalStore: finalGoalStore,
                milestoneStore: milestoneStore,
                day: day
            )
            pendingRefreshTask = nil
        case .active:
            break
        case .inactive:
            guard inactiveDelay > .zero else {
                GoalDataRefreshCoordinator.refreshAfterGoalDataChange(
                    finalGoalStore: finalGoalStore,
                    milestoneStore: milestoneStore,
                    day: day
                )
                pendingRefreshTask = nil
                return
            }

            pendingRefreshTask = Task { @MainActor [weak self, weak finalGoalStore, weak milestoneStore] in
                do {
                    try await Task.sleep(for: inactiveDelay)
                } catch {
                    return
                }

                guard !Task.isCancelled,
                      let finalGoalStore,
                      let milestoneStore else { return }

                GoalDataRefreshCoordinator.refreshAfterGoalDataChange(
                    finalGoalStore: finalGoalStore,
                    milestoneStore: milestoneStore,
                    day: day
                )
                self?.pendingRefreshTask = nil
            }
        @unknown default:
            pendingRefreshTask = nil
        }
    }

    deinit {
        pendingRefreshTask?.cancel()
    }
}
