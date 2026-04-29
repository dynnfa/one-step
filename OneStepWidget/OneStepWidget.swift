import OneStepCore
import SwiftUI
import WidgetKit

struct OneStepWidget: Widget {
    static let kind = "OneStepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OneStepTimelineProvider()) { entry in
            OneStepWidgetView(entry: entry)
        }
        .configurationDisplayName("One Step")
        .description("Complete today's long-term goals from the desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OneStepWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OneStepWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            HStack {
                Text("One Step")
                    .font(family == .systemSmall ? .caption.bold() : .headline)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.goals.isEmpty {
                Spacer(minLength: 0)
                Text("Create a goal in the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(entry.goals) { goal in
                    WidgetGoalRowView(goal: goal, compact: family == .systemSmall)
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.background, for: .widget)
        .padding()
    }
}
