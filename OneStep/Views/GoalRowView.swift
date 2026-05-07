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
    let onCheckIn: () -> Void
    let onUndo: () -> Void
    let onSetActive: (Bool) -> Void
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
            .disabled(!milestone.isActive || milestone.completedAt != nil)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(milestone.title).font(.headline)
                    if milestone.isActive {
                        Text("active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15))
                            .clipShape(Capsule())
                    } else if milestone.completedAt == nil {
                        Text("inactive")
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
                if milestone.completedAt == nil {
                    if milestone.isActive {
                        Button { onSetActive(false) } label: {
                            Text("Deactivate")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .overlay(
                                    Capsule().stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    } else {
                        Button { onSetActive(true) } label: {
                            Text("Activate")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .overlay(
                                    Capsule().stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
                Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                    .font(.headline.monospacedDigit())
            }

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
