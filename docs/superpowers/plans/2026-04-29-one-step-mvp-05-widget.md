# One Step MVP 05 Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary Widget with final small, medium, and large layouts and harden AppIntent behavior for stale Widget taps.

**Architecture:** Widget rendering uses `WidgetGoalSnapshot` only. Timeline reads through `GoalRepository.activeGoalsForWidget(limit:day:)`. `CompleteGoalIntent` writes through `GoalRepository.completeToday`, logs stale missing or archived goals, and requests Widget timeline reload.

**Tech Stack:** WidgetKit, SwiftUI, AppIntents, `OneStepCore`, `os.Logger`.

---

## Agent Boundary

Execute only Widget and AppIntent work. Do not change main app UI unless a compile error requires a small integration fix.

## Files

- Create: `OneStepWidget/WidgetGoalRowView.swift`
- Modify: `OneStepWidget/OneStepWidget.swift`
- Modify: `OneStepWidget/OneStepTimelineProvider.swift`
- Modify: `OneStepWidget/CompleteGoalIntent.swift`

## Task 1: Widget Row

- [ ] **Step 1: Write row view**

Write `OneStepWidget/WidgetGoalRowView.swift`:

```swift
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
```

## Task 2: Final Widget Layout

- [ ] **Step 1: Write final Widget file**

Write `OneStepWidget/OneStepWidget.swift`:

```swift
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
```

- [ ] **Step 2: Confirm family limits**

`OneStepWidget/OneStepTimelineProvider.swift` must map Widget families to limits:

```swift
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

## Task 3: Harden CompleteGoalIntent

- [ ] **Step 1: Replace intent implementation**

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
        } catch GoalRepositoryError.goalNotFound {
            OneStepLog.appIntent.error("Stale widget tap ignored because goal was missing: \(goalID)")
        } catch GoalRepositoryError.goalNotActive {
            OneStepLog.appIntent.error("Stale widget tap ignored because goal was archived: \(goalID)")
        } catch {
            OneStepLog.appIntent.error("CompleteGoalIntent failed: \(error.localizedDescription)")
        }

        return .result()
    }
}
```

- [ ] **Step 2: Run core stale tests**

```bash
swift test --package-path Packages/OneStepCore --filter GoalRepositoryCompletionTests
```

Expected: tests for missing and archived goals pass.

## Task 4: Widget Build and Manual Verification

- [ ] **Step 1: Build Widget extension**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStepWidgetExtension -destination 'platform=macOS' build
```

If the scheme name differs, run:

```bash
xcodebuild -list -project OneStep.xcodeproj
```

Then build the listed Widget extension scheme.

- [ ] **Step 2: Manual Widget verification**

Create 5 active goals in this order:

```text
Vocabulary
Exercise
Reading
Piano
Writing
```

Verify:

```text
Small Widget shows 1 goal.
Medium Widget shows 3 goals.
Large Widget shows 5 goals.
Long title and action strings clip to one line without overlapping progress text.
Clicking an incomplete Widget row creates exactly one completion for today.
Clicking an already completed row does not create a duplicate completion.
Archiving a goal visible in a stale Widget timeline logs a no-op and does not mutate that goal.
```

- [ ] **Step 3: Commit**

```bash
git add OneStepWidget
git commit -m "feat: build final widget workflow"
```

## Self-Review

- Widget uses snapshots only.
- Widget family limits are explicit.
- Stale missing and archived goal taps are logged and ignored.
- App UI was not redesigned in this plan.
