import OneStepCore

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
