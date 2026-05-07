import OneStepCore
import WidgetKit

struct OneStepWidgetEntry: TimelineEntry {
    let date: Date
    let milestones: [WidgetMilestoneSnapshot]
}

struct OneStepTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OneStepWidgetEntry {
        OneStepWidgetEntry(date: Date(), milestones: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (OneStepWidgetEntry) -> Void) {
        let family = context.family
        Task { @MainActor in
            completion(loadEntry(family: family))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OneStepWidgetEntry>) -> Void) {
        let family = context.family
        Task { @MainActor in
            let entry = loadEntry(family: family)
            let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    @MainActor
    private func loadEntry(family: WidgetFamily) -> OneStepWidgetEntry {
        do {
            let repository = try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            let milestones = try repository.activeMilestonesForWidget(limit: family.goalLimit, day: .today)
            return OneStepWidgetEntry(date: Date(), milestones: milestones)
        } catch {
            OneStepLog.widget.error("Timeline load failed: \(error.localizedDescription, privacy: .public)")
            return OneStepWidgetEntry(date: Date(), milestones: [])
        }
    }
}

private extension WidgetFamily {
    var goalLimit: Int {
        switch self {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 4
        case .systemLarge, .systemExtraLarge:
            return 12
        default:
            return 3
        }
    }
}
