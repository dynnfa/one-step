import AppIntents
import OneStepCore
import SwiftUI
import WidgetKit

struct WidgetGoalRowView: View {
    let goal: WidgetGoalSnapshot
    let compact: Bool

    var body: some View {
        Button(intent: CompleteGoalIntent(goalID: goal.id)) {
            HStack(spacing: 8) {
                Image(systemName: goal.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(goal.isCompletedToday ? .green : .secondary)
                    .font(compact ? .body : .title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(compact ? .caption.bold() : .headline)
                        .lineLimit(1)
                    if !compact {
                        Text(goal.dailyAction)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text("\(goal.completedDays)/\(goal.targetCompletionDays)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(goal.isCompletedToday)
    }
}
