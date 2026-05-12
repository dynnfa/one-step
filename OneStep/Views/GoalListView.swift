import OneStepCore
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Indicator Types

private struct DropHoverState: Equatable {
    let goalID: UUID
    let isAbove: Bool
}

private struct RowDragState {
    let isBeingDragged: Bool
    let isDropTargetAbove: Bool
    let isDropTargetBelow: Bool
}

private struct GoalRowDropDelegate: DropDelegate {
    let goalID: UUID
    let onHoverUpdate: (DropHoverState?) -> Void
    let onPerformDrop: (_ destinationGoalID: UUID, _ insertAbove: Bool) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        true
    }

    func dropEntered(info: DropInfo) {
        onHoverUpdate(DropHoverState(goalID: goalID, isAbove: true))
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        let isAbove = info.location.y < 22
        onHoverUpdate(DropHoverState(goalID: goalID, isAbove: isAbove))
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        onHoverUpdate(nil)
    }

    func performDrop(info: DropInfo) -> Bool {
        let isAbove = info.location.y < 22
        onHoverUpdate(nil)
        return onPerformDrop(goalID, isAbove)
    }
}

private struct DropIndicatorLine: View {
    var body: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(height: 3)
            .padding(.horizontal, 6)
    }
}

// MARK: - GoalListView

struct GoalListView: View {
    @Bindable var finalGoalStore: FinalGoalStore
    @Bindable var milestoneStore: MilestoneGoalStore
    @Bindable var dataPortStore: DataPortStore
    @Binding var isShowingCreateGoal: Bool
    let onImportData: () -> Void
    let onExportData: () -> Void
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
                    targetCalendarDays: goal.targetCalendarDays,
                    colorThemeID: goal.colorThemeID,
                    customColorHex: goal.customColorHex
                )
            ) { title, description, target, colorThemeID, customColorHex in
                finalGoalStore.updateFinalGoal(
                    finalGoalID: goal.id, title: title,
                    goalDescription: description,
                    targetCalendarDays: target,
                    colorThemeID: colorThemeID,
                    customColorHex: customColorHex
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
            statusMessage: dataPortStore.statusMessage,
            errorMessage: dataPortStore.errorMessage,
            onAddGoal: { isShowingCreateGoal = true },
            onImportData: onImportData,
            onExportData: onExportData,
            onSelectGoal: { finalGoalStore.select($0) },
            onMoveActiveGoal: moveActiveGoal
        )
    }

    private func moveActiveGoal(_ draggedGoalID: UUID, to destinationGoalID: UUID, insertAbove: Bool) -> Bool {
        guard draggedGoalID != destinationGoalID,
              let sourceIndex = activeGoals.firstIndex(where: { $0.id == draggedGoalID }),
              let destIndex = activeGoals.firstIndex(where: { $0.id == destinationGoalID }) else {
            return false
        }

        let targetIndex = computeGoalReorderIndex(source: sourceIndex, dest: destIndex, insertAbove: insertAbove)
        finalGoalStore.move(from: IndexSet(integer: sourceIndex), to: targetIndex)
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
                    onEditMilestone: { ms in editingMilestone = ms },
                    onDeleteMilestone: deleteMilestone,
                    onSetActive: { msID, isActive in milestoneStore.setMilestoneActive(milestoneGoalID: msID, finalGoalID: goal.id, isActive: isActive) },
                    onRecentActivityDayLimitChange: { dayLimit in
                        milestoneStore.ensureRecentActivityDayLimit(dayLimit, finalGoalID: goal.id)
                    }
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

// MARK: - Sidebar

private struct GoalSidebarView: View {
    let activeGoals: [FinalGoalListSnapshot]
    let archivedGoals: [FinalGoalListSnapshot]
    let selectedFinalGoalID: UUID?
    let statusMessage: String?
    let errorMessage: String?
    let onAddGoal: () -> Void
    let onImportData: () -> Void
    let onExportData: () -> Void
    let onSelectGoal: (UUID) -> Void
    let onMoveActiveGoal: (UUID, UUID, Bool) -> Bool

    @State private var dropHoverState: DropHoverState?
    @State private var draggedGoalID: UUID?
    @State private var isSidebarDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            } else if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    GoalSidebarSection(title: "Active") {
                        ForEach(activeGoals) { goal in
                            GoalSidebarRowView(
                                goal: goal,
                                isSelected: selectedFinalGoalID == goal.id,
                                dragState: RowDragState(
                                    isBeingDragged: draggedGoalID == goal.id,
                                    isDropTargetAbove: dropHoverState?.goalID == goal.id && dropHoverState?.isAbove == true,
                                    isDropTargetBelow: dropHoverState?.goalID == goal.id && dropHoverState?.isAbove == false
                                ),
                                onSelect: { onSelectGoal(goal.id) }
                            )
                            .onDrag {
                                draggedGoalID = goal.id
                                return NSItemProvider(object: goal.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: GoalRowDropDelegate(
                                    goalID: goal.id,
                                    onHoverUpdate: { newState in
                                        guard draggedGoalID != nil else {
                                            dropHoverState = nil
                                            return
                                        }
                                        dropHoverState = newState
                                    },
                                    onPerformDrop: { destinationGoalID, insertAbove in
                                        dropHoverState = nil
                                        guard let draggedID = draggedGoalID else { return false }
                                        draggedGoalID = nil
                                        var result = false
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            result = onMoveActiveGoal(draggedID, destinationGoalID, insertAbove)
                                        }
                                        return result
                                    }
                                )
                            )
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
                .onDrop(of: [.text], isTargeted: sidebarDropTargetBinding) { _ in
                    clearDragState()
                    return false
                }
            }
        }
        .background(.bar)
        .onChange(of: activeGoals.map(\.id)) { _, _ in
            clearDragState()
        }
    }

    private var sidebarDropTargetBinding: Binding<Bool> {
        Binding(
            get: { isSidebarDropTargeted },
            set: { isTargeted in
                isSidebarDropTargeted = isTargeted
                if !isTargeted {
                    clearDragState()
                }
            }
        )
    }

    private func clearDragState() {
        draggedGoalID = nil
        dropHoverState = nil
    }

    private var header: some View {
        HStack {
            Text("Goals")
                .font(.headline)
            Spacer()
            Menu {
                Button(action: onImportData) {
                    Label("Import Data...", systemImage: "square.and.arrow.down")
                }
                Button(action: onExportData) {
                    Label("Export Data...", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .help("Import or Export Data")

            Button(action: onAddGoal) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Add Goal")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Sidebar Components

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
    var dragState: RowDragState?
    let onSelect: () -> Void

    private var isBeingDragged: Bool { dragState?.isBeingDragged == true }

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
                .fill(isSelected && !isBeingDragged ? Color.accentColor.opacity(0.18) : Color.clear)
        }
        .redacted(reason: isBeingDragged ? .placeholder : [])
        .overlay {
            if isBeingDragged {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .overlay(alignment: .top) {
            if dragState?.isDropTargetAbove == true {
                DropIndicatorLine()
                    .offset(y: -1)
            }
        }
        .overlay(alignment: .bottom) {
            if dragState?.isDropTargetBelow == true {
                DropIndicatorLine()
                    .offset(y: 1)
            }
        }
    }
}
