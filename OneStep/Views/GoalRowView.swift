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
                Text("\(milestone.remainingDays) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(milestone.completionRate, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if milestone.completedAt == nil {
                Button {
                    onSetActive(!milestone.isActive)
                } label: {
                    Image(systemName: milestone.isActive ? "pause.circle" : "play.circle")
                }
                .buttonStyle(.plain)
                .help(milestone.isActive ? "Deactivate milestone" : "Activate milestone")
            }

            Menu {
                Button("Edit", action: onEdit)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .frame(width: 32)
        }
        .padding(.vertical, 10)
    }
}
