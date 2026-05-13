import OneStepCore
import SwiftUI
import WidgetKit

struct OneStepWidget: Widget {
    static let kind = AppIdentifiers.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OneStepTimelineProvider()) { entry in
            OneStepWidgetView(entry: entry)
        }
        .configurationDisplayName("One Step")
        .description("Complete today's milestone from the desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OneStepWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OneStepWidgetEntry

    private static let rowSpacing: CGFloat = 6

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 4 : 6) {
            header

            if entry.milestones.isEmpty {
                Spacer(minLength: 0)
                Text("Create a goal in the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else if isSmall {
                VStack(alignment: .leading, spacing: Self.rowSpacing) {
                    ForEach(Array(entry.milestones.prefix(2))) { milestone in
                        WidgetGoalRowView(milestone: milestone, compact: true, narrow: false)
                    }
                }
                Spacer(minLength: 0)
            } else {
                twoColumnContent
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.background, for: .widget)
        .padding(EdgeInsets(
            top: isSmall ? 4 : 10,
            leading: isSmall ? 4 : 10,
            bottom: isSmall ? 4 : 10,
            trailing: isSmall ? 4 : 10
        ))
    }

    private var header: some View {
        HStack {
            Text("One Step")
                .font(isSmall ? .caption.bold() : .headline)
            Spacer()
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var twoColumnContent: some View {
        let milestones = entry.milestones
        let splitIndex = (milestones.count + 1) / 2
        let leftHalf = Array(milestones[..<splitIndex])
        let rightHalf = Array(milestones[splitIndex...])

        return HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                ForEach(leftHalf) { milestone in
                    WidgetGoalRowView(milestone: milestone, compact: false, narrow: true)
                }
            }
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                ForEach(rightHalf) { milestone in
                    WidgetGoalRowView(milestone: milestone, compact: false, narrow: true)
                }
            }
        }
    }
}
