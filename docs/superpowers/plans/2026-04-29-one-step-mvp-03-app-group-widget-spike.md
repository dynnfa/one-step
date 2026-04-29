# One Step MVP 03 App Group Widget Spike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove the riskiest path: main app creates a goal, Widget timeline reads it from the shared App Group store, AppIntent completes it, and Widget reload is requested.

**Architecture:** Use temporary app UI and temporary Widget UI to validate the App Group and AppIntent write path before full product UI. Keep all data writes inside `GoalRepository`. Log enough information to distinguish entitlement, store creation, repository, timeline, and intent failures.

**Tech Stack:** SwiftUI, WidgetKit, AppIntents, SwiftData through `OneStepCore`, `os.Logger`.

---

## Agent Boundary

Execute only the shared-store spike. Temporary UI is acceptable in this plan because the next app and Widget plans replace it.

## Files

- Create: `Packages/OneStepCore/Sources/OneStepCore/Logging/OneStepLog.swift`
- Modify: `OneStep/App/AppConstants.swift`
- Modify: `OneStep/Views/ContentView.swift`
- Create: `OneStepWidget/OneStepTimelineProvider.swift`
- Create: `OneStepWidget/CompleteGoalIntent.swift`
- Modify: `OneStepWidget/OneStepWidget.swift`

## Task 1: Logging

- [ ] **Step 1: Add shared logger**

Write `Packages/OneStepCore/Sources/OneStepCore/Logging/OneStepLog.swift`:

```swift
import OSLog

public enum OneStepLog {
    public static let subsystem = "dev.dynnfa.OneStep"
    public static let repository = Logger(subsystem: subsystem, category: "repository")
    public static let widget = Logger(subsystem: subsystem, category: "widget")
    public static let appIntent = Logger(subsystem: subsystem, category: "app-intent")
    public static let store = Logger(subsystem: subsystem, category: "store")
}
```

- [ ] **Step 2: Build package**

```bash
swift test --package-path Packages/OneStepCore
```

Expected: package tests pass.

## Task 2: Temporary App Spike UI

- [ ] **Step 1: Ensure shared constant is visible**

`OneStep/App/AppConstants.swift` must contain:

```swift
import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.dev.dynnfa.OneStep"
}
```

If the Widget target cannot see this file, duplicate the same file in `OneStepWidget/AppConstants.swift` and add it to the Widget target.

- [ ] **Step 2: Replace ContentView with spike creator**

Write `OneStep/Views/ContentView.swift`:

```swift
import OneStepCore
import SwiftUI

struct ContentView: View {
    @State private var message = "Create a spike goal, then add the Widget."

    var body: some View {
        VStack(spacing: 16) {
            Text("One Step")
                .font(.largeTitle.bold())

            Text(message)
                .foregroundStyle(.secondary)

            Button("Create Spike Goal") {
                createSpikeGoal()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 640, minHeight: 420)
    }

    @MainActor
    private func createSpikeGoal() {
        do {
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            let id = try repository.createGoal(CreateGoalInput(
                title: "Vocabulary",
                dailyAction: "Study 30 minutes",
                targetCompletionDays: 200,
                startDay: .today
            ))
            message = "Created spike goal \(id.uuidString.prefix(8)). Add or refresh the Widget."
        } catch {
            OneStepLog.store.error("Spike goal creation failed: \(error.localizedDescription)")
            message = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
```

## Task 3: Timeline Provider and Intent

- [ ] **Step 1: Add timeline provider**

Write `OneStepWidget/OneStepTimelineProvider.swift`:

```swift
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
        completion(loadEntry(family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OneStepWidgetEntry>) -> Void) {
        let entry = loadEntry(family: context.family)
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadEntry(family: WidgetFamily) -> OneStepWidgetEntry {
        do {
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            let goals = try repository.activeGoalsForWidget(limit: family.goalLimit, day: .today)
            return OneStepWidgetEntry(date: Date(), goals: goals)
        } catch {
            OneStepLog.widget.error("Timeline load failed: \(error.localizedDescription)")
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
```

- [ ] **Step 2: Add completion intent**

Write `OneStepWidget/CompleteGoalIntent.swift`:

```swift
import AppIntents
import OneStepCore
import WidgetKit

struct CompleteGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Goal"

    @Parameter(title: "Goal ID")
    var goalID: String

    init() {}

    init(goalID: UUID) {
        self.goalID = goalID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Widget tap -> AppIntent -> GoalRepository -> SwiftData/App Group -> Widget reload
        guard let id = UUID(uuidString: goalID) else {
            OneStepLog.appIntent.error("Invalid goal ID: \(goalID)")
            return .result()
        }

        do {
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            try repository.completeToday(goalID: id, day: .today)
            WidgetCenter.shared.reloadTimelines(ofKind: OneStepWidget.kind)
        } catch {
            OneStepLog.appIntent.error("CompleteGoalIntent failed: \(error.localizedDescription)")
        }

        return .result()
    }
}
```

- [ ] **Step 3: Add temporary Widget view**

Write `OneStepWidget/OneStepWidget.swift`:

```swift
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
        }
        .configurationDisplayName("One Step")
        .description("Complete today's long-term goals from the desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

## Task 4: Spike Verification

- [ ] **Step 1: Build app**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

Expected: app build succeeds.

- [ ] **Step 2: Build Widget extension**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStepWidgetExtension -destination 'platform=macOS' build
```

If the scheme name differs, run:

```bash
xcodebuild -list -project OneStep.xcodeproj
```

Then build the listed Widget extension scheme.

- [ ] **Step 3: Manual App Group verification**

1. Run the app.
2. Click `Create Spike Goal`.
3. Add the One Step Widget.
4. Confirm the Widget reads `Vocabulary`.
5. Click the Widget goal.
6. Confirm the Widget eventually shows completed.
7. Open Console and filter subsystem `dev.dynnfa.OneStep` if any step fails.

- [ ] **Step 4: Commit**

```bash
git add OneStep OneStepWidget Packages/OneStepCore
git commit -m "feat: prove app group widget check-in"
```

## Self-Review

- Shared App Group path is proven manually.
- Widget writes through `GoalRepository`, not directly through SwiftData.
- Temporary UI is limited to spike verification.
