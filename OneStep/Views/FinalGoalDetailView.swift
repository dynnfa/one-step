import OneStepCore
import SwiftUI

struct FinalGoalDetailView: View {
    let goal: FinalGoalListSnapshot
    let milestones: [MilestoneGoalSnapshot]
    let errorMessage: String?
    let onAddMilestone: () -> Void
    let onToggleArchive: () -> Void
    let onEditGoal: () -> Void
    let onDeleteGoal: () -> Void
    let onCheckIn: (UUID) -> Void
    let onUndo: (UUID) -> Void
    let onEditMilestone: (MilestoneGoalSnapshot) -> Void
    let onDeleteMilestone: (MilestoneGoalSnapshot) -> Void
    let onSetActive: (UUID, Bool) -> Void
    let onRecentActivityDayLimitChange: (Int) -> Void

    @State private var isConfirmingGoalDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            if milestones.isEmpty {
                milestoneEmptyState
            } else {
                milestoneList
            }
        }
        .confirmationDialog(
            "Delete Goal?",
            isPresented: $isConfirmingGoalDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Goal", role: .destructive, action: onDeleteGoal)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the goal, its milestones, and their completion history.")
        }
    }

    private var actionPolicy: FinalGoalDetailActionPolicy {
        FinalGoalDetailActionPolicy(goal: goal)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title).font(.largeTitle.bold())
                if let desc = goal.goalDescription, !desc.isEmpty {
                    Text(desc).foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    if goal.totalMilestoneCount > 0 {
                        Label("\(goal.completedMilestoneCount)/\(goal.totalMilestoneCount) milestones", systemImage: "list.checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let remaining = goal.remainingCalendarDays {
                        Label("\(remaining) calendar days left", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Menu {
                if actionPolicy.canMutateGoal {
                    Button("Edit Goal", action: onEditGoal)
                }
                if actionPolicy.canMutateMilestones {
                    Button("Add Milestone", action: onAddMilestone)
                }
                if actionPolicy.canMutateGoal || actionPolicy.canMutateMilestones {
                    Divider()
                }
                Button(actionPolicy.archiveButtonTitle, action: onToggleArchive)
                Button("Delete Goal", role: .destructive) {
                    isConfirmingGoalDelete = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
        }
        .padding()
    }

    private var milestoneEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.tint)
            Text("No milestones yet.")
                .font(.title3.bold())
            Text("Break this goal into sequential phases.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            if actionPolicy.canMutateMilestones {
                Button("Add First Milestone", action: onAddMilestone)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var milestoneList: some View {
        List {
            Section {
                ForEach(milestones) { milestone in
                    MilestoneGoalRowView(
                        milestone: milestone,
                        isReadOnly: !actionPolicy.canMutateMilestones,
                        onCheckIn: { onCheckIn(milestone.id) },
                        onUndo: { onUndo(milestone.id) },
                        onEdit: { onEditMilestone(milestone) },
                        onDelete: { onDeleteMilestone(milestone) },
                        onSetActive: { isActive in onSetActive(milestone.id, isActive) },
                        onRecentActivityDayLimitChange: onRecentActivityDayLimitChange
                    )
                }
            }
        }
        .listStyle(.inset)
    }
}

struct FinalGoalDetailActionPolicy {
    let goal: FinalGoalListSnapshot

    var canMutateGoal: Bool {
        goal.archivedAt == nil
    }

    var canMutateMilestones: Bool {
        goal.archivedAt == nil
    }

    var archiveButtonTitle: String {
        goal.archivedAt == nil ? "Archive Goal" : "Reactivate Goal"
    }
}
