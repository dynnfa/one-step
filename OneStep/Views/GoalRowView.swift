import OneStepCore
import SwiftUI

struct FinalGoalRowView: View {
    let goal: FinalGoalListSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title).font(.headline)
                if goal.totalMilestoneCount > 0 {
                    Text("\(goal.completedMilestoneCount)/\(goal.totalMilestoneCount) milestones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if goal.archivedAt != nil {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MilestoneGoalRowView: View {
    let milestone: MilestoneGoalSnapshot
    let isReadOnly: Bool
    let onCheckIn: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: milestone.isCompletedToday ? onUndo : onCheckIn) {
                Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(isReadOnly || !milestone.isActive || milestone.completedAt != nil)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(milestone.title).font(.headline)
                    if milestone.isActive {
                        Text("current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15))
                            .clipShape(Capsule())
                    } else if milestone.completedAt == nil {
                        Text("up next")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                    if milestone.completedAt != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }

                }
                RecentActivityView(activity: milestone.recentActivity)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                    .font(.headline.monospacedDigit())
            }

            if !isReadOnly {
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive) {
                        isConfirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.button)
                .frame(width: 32)
            }
        }
        .padding(.vertical, 10)
        .confirmationDialog(
            "Delete Milestone?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Milestone", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the milestone and its completion history.")
        }
    }
}
