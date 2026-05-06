# Architecture

One Step has three main areas.

## Project Layout

```text
one-step/
    OneStep/              macOS app (SwiftUI)
        App/              app entry, constants, FinalGoalStore, MilestoneGoalStore
        Views/            goal list, detail, forms, empty states
        OneStep.entitlements
    OneStepWidget/        Widget extension (WidgetKit + AppIntent)
        OneStepWidget.swift
        CompleteGoalIntent.swift
        OneStepTimelineProvider.swift
        WidgetGoalRowView.swift
        AppConstants.swift
        OneStepWidget.entitlements
    Packages/
        OneStepCore/      shared local Swift package
            Sources/OneStepCore/
                Models/         FinalGoal, MilestoneGoal, DailyCompletion (SwiftData @Model)
                Persistence/    OneStepModelContainerFactory
                Repositories/   FinalGoalRepository, MilestoneGoalRepository
                Snapshots/      FinalGoalListSnapshot, MilestoneGoalSnapshot, WidgetMilestoneSnapshot, Create/Update input structs
                Dates/          LocalDay
                Logging/        OneStepLog
            Tests/OneStepCoreTests/
```

## Dependency Direction

```text
OneStep.app ───────────────┐
                           ▼
                     OneStepCore
                           ▲
OneStepWidgetExtension ────┘
```

`OneStepCore` owns models, persistence, repository logic, date normalization, snapshot structs, and domain errors. It does not import SwiftUI view types or WidgetKit UI types.

The app and Widget depend on `OneStepCore`. Neither the app nor the Widget should contain direct SwiftData fetches, model mutations, or date normalization logic outside the repository layer.

## Shared Persistence

The app and Widget share a SwiftData `ModelContainer` stored in the App Group container `group.dev.dynnfa.OneStep`.

- `OneStepModelContainerFactory.makeShared(appGroupIdentifier:)` resolves the container URL, creates the directory if needed, and returns a `ModelContainer` pointed at the shared SQLite store.
- Both targets include the same App Group identifier in their entitlements and in `AppConstants.appGroupIdentifier`.
- The store file lives at `~/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite`.

## Repository Boundary

`FinalGoalRepository` and `MilestoneGoalRepository` own all persistence rules.

- All reads and writes go through the repositories. App views and Widget code do not touch SwiftData models directly.
- The repositories return plain snapshot structs (`FinalGoalListSnapshot`, `MilestoneGoalSnapshot`, `WidgetMilestoneSnapshot`). UI code renders these snapshots.
- `FinalGoalRepository.shared(appGroupIdentifier:)` and `MilestoneGoalRepository.shared(appGroupIdentifier:)` create repositories backed by the shared App Group store.
- Tests use repositories backed by an in-memory container from `OneStepModelContainerFactory.makeInMemory()`.

## Active Milestones

Each active `FinalGoal` may have multiple active incomplete milestones. `MilestoneGoal.isActive` is stored independently from `completedAt`, and only milestones where `isActive == true` and `completedAt == nil` can accept check-ins. When a milestone reaches its target, the repository sets `completedAt` and forces `isActive = false`; it does not automatically activate another milestone.

## Widget Tap Flow

```text
Widget tap
    → CompleteGoalIntent.perform()
        → MilestoneGoalRepository.completeToday(milestoneGoalID, LocalDay.today)
            → validates milestone is active, incomplete, and parent FinalGoal is active
            → SwiftData store in App Group container
                → WidgetCenter.shared.reloadTimelines(ofKind:)
                    → Widget shows completed state
```

`CompleteGoalIntent` catches repository errors and logs them via `OneStepLog.appIntent`. Stale taps for missing, archived-parent, inactive, or completed milestones are logged and no-oped without crashing.

## Timeline Provider

`OneStepTimelineProvider` loads milestones on a 15-minute refresh cycle. Each refresh calls `MilestoneGoalRepository.activeMilestonesForWidget(limit:day:)` with a limit determined by the Widget family. The method returns active incomplete milestones from active final goals, ordered by final goal order and then milestone order until the widget-family limit is reached.

## Logging

`OneStepLog` provides structured log categories:

- `OneStepLog.repository` — persistence and data-layer errors
- `OneStepLog.widget` — timeline load failures
- `OneStepLog.appIntent` — AppIntent execution errors

All categories use `os.Logger` with the subsystem `dev.dynnfa.OneStep`. Filter Console.app by subsystem to isolate One Step log lines.

## Rules

1. **Do not duplicate persistence logic.** SwiftData models stay in `OneStepCore`. The app and Widget go through `FinalGoalRepository` and `MilestoneGoalRepository`.
2. **Render snapshots, not models.** UI code receives snapshot structs. It does not own data rules or validation.
3. **Keep the App Group identifier consistent.** Both `AppConstants.swift` files and both entitlements files must match.
4. **Log failures visibly.** Widget timeline errors use `privacy: .public` so they appear in Console without needing a debug build.
