import WidgetKit
import SwiftUI

struct OneStepWidgetEntry: TimelineEntry {
    let date: Date
}

struct OneStepWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OneStepWidgetEntry {
        OneStepWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (OneStepWidgetEntry) -> Void) {
        completion(OneStepWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OneStepWidgetEntry>) -> Void) {
        completion(Timeline(entries: [OneStepWidgetEntry(date: Date())], policy: .never))
    }
}

struct OneStepWidgetEntryView: View {
    let entry: OneStepWidgetEntry

    var body: some View {
        Text("One Step")
            .font(.headline)
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct OneStepWidget: Widget {
    let kind = "OneStepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OneStepWidgetProvider()) { entry in
            OneStepWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("One Step")
        .description("Track today's long-term goal progress.")
        .supportedFamilies([.systemSmall])
    }
}
