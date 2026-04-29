# Architecture

One Step has three main areas.

## Project Layout

```text
one-step/
    OneStep/              macOS app (SwiftUI)
        App/              app entry, constants, GoalStore
        Views/            goal list, forms, empty states
        OneStep.entitlements
    OneStepWidget/        Widget extension (WidgetKit + AppIntent)
        OneStepWidget.swift
        CompleteGoalIntent.swift
        OneStepTimelineProvider.swift
        AppConstants.swift
        OneStepWidget.entitlements
    Packages/
        OneStepCore/      shared local Swift package
            Sources/OneStepCore/
                Models/         Goal, DailyCompletion (SwiftData @Model)
                Persistence/    OneStepModelContainerFactory
                Repositories/   GoalRepository
                Snapshots/      WidgetGoalSnapshot, GoalListSnapshot, CreateGoalInput, UpdateGoalInput
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

The app and Widget depend on `OneStepCore`. Neither the app nor the Widget should contain direct SwiftData fetches, model mutations, or date normalization logic outside the repository.

## Shared Persistence

The app and Widget share a SwiftData `ModelContainer` stored in the App Group container `group.dev.dynnfa.OneStep`.

- `OneStepModelContainerFactory.makeShared(appGroupIdentifier:)` resolves the container URL, creates the directory if needed, and returns a `ModelContainer` pointed at the shared SQLite store.
- Both targets include the same App Group identifier in their entitlements and in `AppConstants.appGroupIdentifier`.
- The store file lives at `~/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite`.

## Repository Boundary

`GoalRepository` is the single owner of all persistence rules.

- All reads and writes go through the repository. App views and Widget code do not touch SwiftData models directly.
- The repository returns plain snapshot structs (`WidgetGoalSnapshot`, `GoalListSnapshot`). UI code renders these snapshots.
- `GoalRepository.shared(appGroupIdentifier:)` creates a repository backed by the shared App Group store.
- Tests use `GoalRepository` backed by an in-memory container from `OneStepModelContainerFactory.makeInMemory()`.

## Widget Tap Flow

```text
Widget tap
    → CompleteGoalIntent.perform()
        → GoalRepository.completeToday(goalID, LocalDay.today)
            → SwiftData store in App Group container
                → WidgetCenter.shared.reloadTimelines(ofKind:)
                    → Widget shows completed state
```

`CompleteGoalIntent` catches repository errors and logs them via `OneStepLog.appIntent`. Stale taps for missing or archived goals are logged and no-oped without crashing.

## Timeline Provider

`OneStepTimelineProvider` loads goals on a 15-minute refresh cycle. Each refresh calls `GoalRepository.activeGoalsForWidget(limit:day:)` with a limit determined by the Widget family.

## Logging

`OneStepLog` provides structured log categories:

- `OneStepLog.repository` — persistence and data-layer errors
- `OneStepLog.widget` — timeline load failures
- `OneStepLog.appIntent` — AppIntent execution errors

All categories use `os.Logger` with the subsystem `dev.dynnfa.OneStep`. Filter Console.app by subsystem to isolate One Step log lines.

## Rules

1. **Do not duplicate persistence logic.** SwiftData models stay in `OneStepCore`. The app and Widget go through `GoalRepository`.
2. **Render snapshots, not models.** UI code receives snapshot structs. It does not own data rules or validation.
3. **Keep the App Group identifier consistent.** Both `AppConstants.swift` files and both entitlements files must match.
4. **Log failures visibly.** Widget timeline errors use `privacy: .public` so they appear in Console without needing a debug build.
