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
            if goal.completedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if goal.archivedAt != nil {
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
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: milestone.isCompletedToday ? onUndo : onCheckIn) {
                Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!milestone.isCurrent && milestone.completedAt == nil)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(milestone.title).font(.headline)
                    if milestone.isCurrent {
                        Text("current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15))
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
                Text("\(milestone.remainingDays) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(milestone.completionRate, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Menu {
                Button("Edit", action: onEdit)
                Button("Archive", role: .destructive, action: onArchive)
                    .disabled(milestone.archivedAt != nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .frame(width: 32)
        }
        .padding(.vertical, 10)
    }
}
