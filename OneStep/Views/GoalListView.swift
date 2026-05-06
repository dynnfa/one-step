import OneStepCore
import SwiftUI

struct GoalListView: View {
    @Bindable var finalGoalStore: FinalGoalStore
    @Bindable var milestoneStore: MilestoneGoalStore
    @Binding var isShowingCreateGoal: Bool
    @State private var editingFinalGoal: FinalGoalListSnapshot?
    @State private var editingMilestone: MilestoneGoalSnapshot?
    @State private var isAddingMilestone = false

    private var activeGoals: [FinalGoalListSnapshot] {
        finalGoalStore.finalGoals.filter { $0.archivedAt == nil }
    }

    private var archivedGoals: [FinalGoalListSnapshot] {
        finalGoalStore.finalGoals.filter { $0.archivedAt != nil }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
        }
        .onAppear { finalGoalStore.refresh() }
        .onChange(of: finalGoalStore.selectedFinalGoalID) { _, newID in
            if let newID {
                milestoneStore.refresh(finalGoalID: newID)
            }
        }
        .sheet(item: $editingFinalGoal) { goal in
            FinalGoalEditorView(
                mode: .edit(
                    title: goal.title,
                    goalDescription: goal.goalDescription,
                    targetCalendarDays: goal.targetCalendarDays
                )
            ) { title, description, target in
                finalGoalStore.updateFinalGoal(
                    finalGoalID: goal.id, title: title,
                    goalDescription: description, targetCalendarDays: target
                )
                editingFinalGoal = nil
            }
        }
        .sheet(item: $editingMilestone) { milestone in
            MilestoneGoalEditorView(
                mode: .edit(
                    title: milestone.title,
                    targetCompletionDays: milestone.targetCompletionDays
                )
            ) { title, targetDays in
                milestoneStore.updateMilestone(
                    milestoneGoalID: milestone.id,
                    finalGoalID: milestone.finalGoalID,
                    title: title,
                    targetCompletionDays: targetDays
                )
                editingMilestone = nil
            }
        }
        .sheet(isPresented: $isAddingMilestone) {
            if let fgID = finalGoalStore.selectedFinalGoalID {
                MilestoneGoalEditorView(mode: .create) { title, targetDays in
                    milestoneStore.createMilestone(
                        title: title, targetCompletionDays: targetDays, finalGoalID: fgID
                    )
                    isAddingMilestone = false
                }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $finalGoalStore.selectedFinalGoalID) {
            Section("Active") {
                ForEach(activeGoals) { goal in
                    FinalGoalRowView(goal: goal)
                        .tag(goal.id)
                }
                .onMove(perform: finalGoalStore.move)
            }
            if !archivedGoals.isEmpty {
                Section("Archived") {
                    ForEach(archivedGoals) { goal in
                        FinalGoalRowView(goal: goal)
                            .tag(goal.id)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isShowingCreateGoal = true } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
    }

    // MARK: - Detail

    private var detailPane: some View {
        Group {
            if let selectedID = finalGoalStore.selectedFinalGoalID,
               let goal = finalGoalStore.finalGoals.first(where: { $0.id == selectedID }) {
                FinalGoalDetailView(
                    goal: goal,
                    milestones: milestoneStore.milestones,
                    errorMessage: milestoneStore.errorMessage ?? finalGoalStore.errorMessage,
                    onAddMilestone: { isAddingMilestone = true },
                    onComplete: { finalGoalStore.completeFinalGoal(finalGoalID: goal.id) },
                    onEditGoal: { editingFinalGoal = goal },
                    onCheckIn: { msID in milestoneStore.completeToday(milestoneGoalID: msID, finalGoalID: goal.id) },
                    onUndo: { msID in milestoneStore.uncompleteToday(milestoneGoalID: msID, finalGoalID: goal.id) },
                    onEditMilestone: { ms in editingMilestone = ms }
                )
            } else if finalGoalStore.finalGoals.isEmpty {
                EmptyStateView { isShowingCreateGoal = true }
            } else {
                ContentUnavailableView(
                    "Select a Goal",
                    systemImage: "target",
                    description: Text("Choose a goal from the sidebar to view its milestones.")
                )
            }
        }
    }
}
