import OneStepCore
import SwiftUI

struct GoalListView: View {
    @Bindable var store: GoalStore
    @Binding var isShowingCreateGoal: Bool
    @State private var editingGoal: GoalListSnapshot?

    private var activeGoals: [GoalListSnapshot] { store.goals.filter { $0.archivedAt == nil } }
    private var archivedGoals: [GoalListSnapshot] { store.goals.filter { $0.archivedAt != nil } }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Active") {
                    ForEach(activeGoals) { goal in
                        Text(goal.title)
                    }
                    .onMove(perform: store.move)
                }
                if !archivedGoals.isEmpty {
                    Section("Archived") {
                        ForEach(archivedGoals) { goal in
                            Text(goal.title).foregroundStyle(.secondary)
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
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let error = store.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                if store.goals.isEmpty {
                    EmptyStateView { isShowingCreateGoal = true }
                } else {
                    List {
                        Section("Active Goals") {
                            ForEach(activeGoals) { goal in
                                GoalRowView(
                                    goal: goal,
                                    onComplete: { store.completeToday(goalID: goal.id) },
                                    onUndo: { store.uncompleteToday(goalID: goal.id) },
                                    onEdit: { editingGoal = goal },
                                    onArchive: { store.archiveGoal(goalID: goal.id) }
                                )
                            }
                            .onMove(perform: store.move)
                        }
                        if !archivedGoals.isEmpty {
                            Section("Archived Goals") {
                                ForEach(archivedGoals) { goal in
                                    GoalRowView(
                                        goal: goal,
                                        onComplete: {},
                                        onUndo: {},
                                        onEdit: { editingGoal = goal },
                                        onArchive: {}
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .onAppear { store.refresh() }
        .sheet(item: $editingGoal) { goal in
            GoalEditorView(
                mode: .edit(
                    title: goal.title,
                    dailyAction: goal.dailyAction,
                    targetCompletionDays: goal.targetCompletionDays
                )
            ) { title, action, target in
                store.updateGoal(goalID: goal.id, title: title, dailyAction: action, targetCompletionDays: target)
                editingGoal = nil
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("One Step").font(.largeTitle.bold())
                Text("Confirm today's progress without turning it into a task manager.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { isShowingCreateGoal = true } label: {
                Label("Add Goal", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
