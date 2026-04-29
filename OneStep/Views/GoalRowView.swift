import OneStepCore
import SwiftUI

struct GoalRowView: View {
    let goal: GoalListSnapshot
    let onComplete: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: goal.isCompletedToday ? onUndo : onComplete) {
                Image(systemName: goal.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title).font(.headline)
                Text(goal.dailyAction).foregroundStyle(.secondary)
                RecentActivityView(activity: goal.recentActivity)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(goal.completedDays)/\(goal.targetCompletionDays)")
                    .font(.headline.monospacedDigit())
                Text("\(goal.remainingDays) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(goal.completionRate, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Menu {
                Button("Edit", action: onEdit)
                Button("Archive", role: .destructive, action: onArchive)
                    .disabled(goal.archivedAt != nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .frame(width: 32)
        }
        .padding(.vertical, 10)
    }
}
