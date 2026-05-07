import AppIntents
import OneStepCore
import SwiftUI
import WidgetKit

struct WidgetGoalRowView: View {
    let milestone: WidgetMilestoneSnapshot
    let compact: Bool
    let narrow: Bool

    var body: some View {
        Button(intent: CompleteGoalIntent(goalID: milestone.id)) {
            HStack(spacing: narrow ? 4 : 6) {
                Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(milestone.isCompletedToday ? .green : .secondary)
                    .font(narrow ? .callout : .title3)

                VStack(alignment: .leading, spacing: narrow ? 1 : 2) {
                    Text(milestone.title)
                        .font(narrow ? .subheadline.bold() : .headline)
                        .lineLimit(1)
                    Text(milestone.parentFinalGoalTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(milestone.isCompletedToday)
    }
}
