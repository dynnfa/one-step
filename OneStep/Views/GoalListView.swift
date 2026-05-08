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
        HStack(spacing: 0) {
            sidebar
                .frame(width: 276)
            Divider()
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            milestoneStore.onMilestonesChanged = {
                finalGoalStore.refresh()
            }
            finalGoalStore.refresh()
        }
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
        GoalSidebarView(
            activeGoals: activeGoals,
            archivedGoals: archivedGoals,
            selectedFinalGoalID: finalGoalStore.selectedFinalGoalID,
            onAddGoal: { isShowingCreateGoal = true },
            onSelectGoal: { finalGoalStore.select($0) },
            onMoveActiveGoal: moveActiveGoal
        )
    }

    private func moveActiveGoal(_ draggedGoalID: UUID, to destinationGoalID: UUID) -> Bool {
        guard draggedGoalID != destinationGoalID,
              let sourceIndex = activeGoals.firstIndex(where: { $0.id == draggedGoalID }),
              let destinationIndex = activeGoals.firstIndex(where: { $0.id == destinationGoalID }) else {
            return false
        }

        finalGoalStore.move(from: IndexSet(integer: sourceIndex), to: destinationIndex)
        return true
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
                    onToggleArchive: { finalGoalStore.toggleFinalGoalArchive(finalGoalID: goal.id) },
                    onEditGoal: { editingFinalGoal = goal },
                    onDeleteGoal: { finalGoalStore.deleteFinalGoal(finalGoalID: goal.id) },
                    onCheckIn: { msID in milestoneStore.completeToday(milestoneGoalID: msID, finalGoalID: goal.id) },
                    onUndo: { msID in milestoneStore.uncompleteToday(milestoneGoalID: msID, finalGoalID: goal.id) },
                    onSetActive: { msID, isActive in
                        milestoneStore.setMilestoneActive(milestoneGoalID: msID, finalGoalID: goal.id, isActive: isActive)
                    },
                    onEditMilestone: { ms in editingMilestone = ms },
                    onDeleteMilestone: deleteMilestone
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

    private func deleteMilestone(_ milestone: MilestoneGoalSnapshot) {
        milestoneStore.deleteMilestone(milestoneGoalID: milestone.id, finalGoalID: milestone.finalGoalID)
    }
}

private struct GoalSidebarView: View {
    let activeGoals: [FinalGoalListSnapshot]
    let archivedGoals: [FinalGoalListSnapshot]
    let selectedFinalGoalID: UUID?
    let onAddGoal: () -> Void
    let onSelectGoal: (UUID) -> Void
    let onMoveActiveGoal: (UUID, UUID) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    GoalSidebarSection(title: "Active") {
                        ForEach(activeGoals) { goal in
                            GoalSidebarRowView(
                                goal: goal,
                                isSelected: selectedFinalGoalID == goal.id,
                                onSelect: { onSelectGoal(goal.id) }
                            )
                            .draggable(goal.id.uuidString)
                            .dropDestination(for: String.self) { items, _ in
                                handleDrop(items, destinationGoalID: goal.id)
                            }
                        }
                    }

                    if !archivedGoals.isEmpty {
                        GoalSidebarSection(title: "Archived") {
                            ForEach(archivedGoals) { goal in
                                GoalSidebarRowView(
                                    goal: goal,
                                    isSelected: selectedFinalGoalID == goal.id,
                                    onSelect: { onSelectGoal(goal.id) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
        }
        .background(.bar)
    }

    private var header: some View {
        HStack {
            Text("Goals")
                .font(.headline)
            Spacer()
            Button(action: onAddGoal) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Add Goal")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func handleDrop(_ items: [String], destinationGoalID: UUID) -> Bool {
        guard let item = items.first,
              let draggedGoalID = UUID(uuidString: item) else {
            return false
        }

        return onMoveActiveGoal(draggedGoalID, destinationGoalID)
    }
}

private struct GoalSidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 8)

            VStack(spacing: 2) {
                content
            }
        }
    }
}

private struct GoalSidebarRowView: View {
    let goal: FinalGoalListSnapshot
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            FinalGoalRowView(goal: goal)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        }
    }
}
