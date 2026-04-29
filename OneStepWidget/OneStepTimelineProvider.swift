import OneStepCore
import WidgetKit

struct OneStepWidgetEntry: TimelineEntry {
    let date: Date
    let goals: [WidgetGoalSnapshot]
}

struct OneStepTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OneStepWidgetEntry {
        OneStepWidgetEntry(date: Date(), goals: [])
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
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            let goals = try repository.activeGoalsForWidget(limit: family.goalLimit, day: .today)
            return OneStepWidgetEntry(date: Date(), goals: goals)
        } catch {
            OneStepLog.widget.error("Timeline load failed: \(error.localizedDescription, privacy: .public)")
            return OneStepWidgetEntry(date: Date(), goals: [])
        }
    }
}

private extension WidgetFamily {
    var goalLimit: Int {
        switch self {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 3
        case .systemLarge, .systemExtraLarge:
            return 5
        default:
            return 3
        }
    }
}
