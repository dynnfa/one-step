import AppIntents
import OneStepCore
import SwiftUI
import WidgetKit

struct OneStepWidget: Widget {
    static let kind = "OneStepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OneStepTimelineProvider()) { entry in
            VStack(alignment: .leading, spacing: 8) {
                if entry.goals.isEmpty {
                    Text("One Step")
                        .font(.headline)
                    Text("Create a goal in the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.goals) { goal in
                        Button(intent: CompleteGoalIntent(goalID: goal.id)) {
                            HStack {
                                Image(systemName: goal.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading) {
                                    Text(goal.title).lineLimit(1)
                                    Text("\(goal.completedDays)/\(goal.targetCompletionDays)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(goal.isCompletedToday)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("One Step")
        .description("Complete today's long-term goals from the desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
