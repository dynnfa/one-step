# One Step MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable MVP of One Step: a local-first macOS app where users create long-term daily goals, review progress in the app, and complete today's progress directly from a desktop Widget.

**Architecture:** This is the master index, not the execution prompt. Execute the linked child plans one at a time so each agent only receives the context it needs. The app uses a native macOS SwiftUI target, a WidgetKit extension, and a shared `OneStepCore` Swift package backed by SwiftData in an App Group container.

**Tech Stack:** macOS 14+, Swift 5.9+, SwiftUI, SwiftData, WidgetKit, AppIntents, XCTest, `os.Logger`, Xcode project with local Swift package `Packages/OneStepCore`.

---

## Source Documents

- Product design: `docs/plans/one-step-design.md`
- Engineering plan: `docs/plans/one-step-engineering-plan.md`
- Test plan: `docs/plans/one-step-test-plan.md`

## Execution Rule

Do not give this master plan to an implementation agent as the only prompt. Give the agent exactly one child plan plus this short instruction:

```text
Execute only the linked plan. First inspect the current repository state. Do not assume prior tasks match the plan exactly; adapt to the code that exists. Run the verification commands in the plan. Stop after the plan's final commit or verification step.
```

## MVP Scope

Included:
- Create, edit, archive, and manually order long-term goals.
- Track one completion per goal per local day.
- Show active goals in the app with completed count, remaining count, completion rate, and recent 30-day activity.
- Store data locally with SwiftData inside `group.dev.dynnfa.OneStep`.
- Render small, medium, and large Widgets from active goal order.
- Complete today's goal directly from the Widget through `CompleteGoalIntent`.
- Treat repeated Widget taps as idempotent no-ops.
- Add developer build instructions and manual Widget QA checklist.

Excluded:
- Reminders, tags, notes, subtasks, categories, rewards, and social features.
- Import/export and iCloud sync.
- Notarized distribution, release artifacts, Homebrew Cask, and Mac App Store packaging.
- Missed-day backfill or streak repair.

## Child Plans

Execute in this order:

1. `docs/superpowers/plans/2026-04-29-one-step-mvp-01-scaffold.md`
   - Creates the Xcode app, Widget target, App Group entitlement, and local Swift package shell.

2. `docs/superpowers/plans/2026-04-29-one-step-mvp-02-core-data.md`
   - Implements `LocalDay`, SwiftData models, snapshots, repository rules, and unit tests.

3. `docs/superpowers/plans/2026-04-29-one-step-mvp-03-app-group-widget-spike.md`
   - Proves app, Widget timeline provider, and AppIntent all read/write the same App Group store.

4. `docs/superpowers/plans/2026-04-29-one-step-mvp-04-main-app.md`
   - Builds the main app workflow: first-run state, create/edit/archive, complete/undo today, reorder, and progress list.

5. `docs/superpowers/plans/2026-04-29-one-step-mvp-05-widget.md`
   - Builds final Widget family layouts and hardens stale Widget tap behavior.

6. `docs/superpowers/plans/2026-04-29-one-step-mvp-06-verification-docs.md`
   - Adds README, manual QA checklist, and final verification commands.

## Shared Contracts

All child plans should converge on these public core types:

```swift
public struct LocalDay: Hashable, Codable, RawRepresentable, Sendable
public final class Goal
public final class DailyCompletion
public struct CreateGoalInput: Equatable, Sendable
public struct UpdateGoalInput: Equatable, Sendable
public struct GoalListSnapshot: Identifiable, Equatable, Sendable
public struct WidgetGoalSnapshot: Identifiable, Equatable, Sendable
public struct RecentActivityDay: Identifiable, Equatable, Sendable
public enum GoalRepositoryError: Error, Equatable, LocalizedError

@MainActor
public struct GoalRepository {
    public static func shared(appGroupIdentifier: String) throws -> GoalRepository
    public func createGoal(_ input: CreateGoalInput) throws -> UUID
    public func updateGoal(goalID: UUID, input: UpdateGoalInput) throws
    public func archiveGoal(goalID: UUID, archivedAt: Date) throws
    public func moveActiveGoal(goalID: UUID, toIndex: Int) throws
    public func completeToday(goalID: UUID, day: LocalDay) throws
    public func uncompleteToday(goalID: UUID, day: LocalDay) throws
    public func goalsForList(day: LocalDay) throws -> [GoalListSnapshot]
    public func activeGoalsForWidget(limit: Int, day: LocalDay) throws -> [WidgetGoalSnapshot]
}
```

The App Group identifier is:

```text
group.dev.dynnfa.OneStep
```

Widget family limits:

```text
small = 1
medium = 3
large = 5
```

## Final Acceptance

- `swift test --package-path Packages/OneStepCore` passes.
- `xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build` succeeds.
- The Widget extension scheme builds. If the scheme name differs, use the scheme listed by `xcodebuild -list -project OneStep.xcodeproj`.
- Manual QA in `docs/qa/widget-mvp-checklist.md` passes.
- A user can create 5 goals, reorder them, add all three Widget sizes, complete today from the Widget, and see exactly one completion record for the local day.

## Execution Handoff

Plan complete and split into child plans under `docs/superpowers/plans/`. Two execution options:

**1. Subagent-Driven (recommended)** - Dispatch a fresh subagent per child plan, review between modules, fast iteration.

**2. Inline Execution** - Execute child plans in this session using executing-plans, one module at a time with checkpoints.

Which approach?
