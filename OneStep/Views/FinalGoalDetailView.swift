import OneStepCore
import SwiftUI

struct FinalGoalDetailView: View {
    let goal: FinalGoalListSnapshot
    let milestones: [MilestoneGoalSnapshot]
    let errorMessage: String?
    let onAddMilestone: () -> Void
    let onComplete: () -> Void
    let onArchive: () -> Void
    let onEditGoal: () -> Void
    let onCheckIn: (UUID) -> Void
    let onUndo: (UUID) -> Void
    let onEditMilestone: (MilestoneGoalSnapshot) -> Void
    let onArchiveMilestone: (UUID) -> Void

    private var activeMilestones: [MilestoneGoalSnapshot] {
        milestones.filter { $0.archivedAt == nil }
    }

    private var allMilestonesDone: Bool {
        !milestones.isEmpty && milestones.allSatisfy { $0.completedAt != nil || $0.archivedAt != nil }
    }

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
                Button("Edit Goal", action: onEditGoal)
                Button("Add Milestone", action: onAddMilestone)
                Divider()
                Button("Complete Goal", action: onComplete)
                    .disabled(!allMilestonesDone)
                Button("Archive", role: .destructive, action: onArchive)
                    .disabled(goal.archivedAt != nil || goal.completedAt != nil)
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
            Button("Add First Milestone", action: onAddMilestone)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var milestoneList: some View {
        List {
            Section {
                ForEach(activeMilestones) { milestone in
                    MilestoneGoalRowView(
                        milestone: milestone,
                        onCheckIn: { onCheckIn(milestone.id) },
                        onUndo: { onUndo(milestone.id) },
                        onEdit: { onEditMilestone(milestone) },
                        onArchive: { onArchiveMilestone(milestone.id) }
                    )
                }
            }
        }
        .listStyle(.inset)
    }
}
