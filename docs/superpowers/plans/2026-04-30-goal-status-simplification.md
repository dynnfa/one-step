# Goal Status Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify goal hierarchy state so `FinalGoal` only uses `archivedAt` to mean ended/complete, while `MilestoneGoal` only uses `completedAt` to mean the phase is done.

**Architecture:** Keep the two-level hierarchy from PR #3, but remove the extra status axis from each level. `FinalGoal.archivedAt == nil` means the goal is active; setting `archivedAt` is the single path for completing/ending/archiving a goal. `MilestoneGoal.completedAt == nil` means the milestone can still become current; milestones cannot be archived independently.

**Tech Stack:** macOS SwiftUI, SwiftData, Observation, WidgetKit, AppIntents, XCTest, `OneStepCore`.

---

## Source Context

- Current PR branch: `feature/goal-hierarchy`
- Current design doc to update: `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`
- Current implementation plan to supersede in part: `docs/superpowers/plans/2026-04-30-goal-hierarchy.md`
- Core models: `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift`, `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift`
- Core repositories: `Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift`, `Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift`
- Snapshots and inputs: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`
- App stores: `OneStep/App/FinalGoalStore.swift`, `OneStep/App/MilestoneGoalStore.swift`
- App views: `OneStep/Views/GoalListView.swift`, `OneStep/Views/FinalGoalDetailView.swift`, `OneStep/Views/GoalRowView.swift`
- Widget: `OneStepWidget/CompleteGoalIntent.swift`, `OneStepWidget/OneStepTimelineProvider.swift`, `OneStepWidget/WidgetGoalRowView.swift`

## Status Model Decision

Use this final state model:

| Model | Status Field | Active Rule | Completion Rule |
|---|---|---|---|
| `FinalGoal` | `archivedAt: Date?` | `archivedAt == nil` | User completes/ends the goal by setting `archivedAt` |
| `MilestoneGoal` | `completedAt: Date?` | `completedAt == nil` | Auto-set when `completedDays >= targetCompletionDays` |

Remove these fields and concepts:

- Remove `FinalGoal.completedAt`.
- Remove `MilestoneGoal.archivedAt`.
- Remove milestone archival repository/store/UI actions.
- Remove the final-goal prerequisite that all milestones must be complete.
- Remove completed-goal vs archived-goal sections in the sidebar; there is only active vs archived final goals.

Keep these concepts:

- `DailyCompletion.goalID` still points to `MilestoneGoal.id`.
- One check-in per milestone per day remains enforced by `DailyCompletion.uniqueKey`.
- Only the current milestone for an active final goal can receive check-ins.
- Current milestone means the first milestone ordered by `sortOrder` where `completedAt == nil`.
- Completed milestones remain visible in the final-goal detail list with a checkmark and no check-in action.
- A final goal can be ended even if zero or more milestones are incomplete.

## Scope Check

This is an incremental status-model cleanup on top of PR #3. It touches persistence, repository rules, snapshots, app UI, widget stale-tap handling, and docs, but all changes serve one connected rule: status belongs to the hierarchy level where it is meaningful. Keep it as one plan with small TDD tasks.

No migration is required. The project is pre-v1.0 and the schema starts fresh.

## File Map

### Core Package

- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift` - delete `completedAt`; update `isActive`.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift` - delete `archivedAt`; update `isActive`.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift` - remove `FinalGoalListSnapshot.completedAt` and `MilestoneGoalSnapshot.archivedAt`.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift` - remove `milestoneGoalNotActive` and `milestonesIncomplete`; adjust `finalGoalNotActive` copy.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift` - delete `completeFinalGoal`; make `archiveFinalGoal` the only end-state method; stop cascading milestone archival.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift` - delete `archiveMilestoneGoal`; use `completedAt == nil` for milestone active/current; fix widget limit after skipping goals with no current milestone.
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/DomainTypeTests.swift`
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift`
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/MilestoneGoalRepositoryTests.swift`

### App Target

- Modify: `OneStep/App/FinalGoalStore.swift` - make completion call set `archivedAt`; remove completed filtering.
- Modify: `OneStep/App/MilestoneGoalStore.swift` - remove milestone archive method.
- Modify: `OneStep/Views/GoalListView.swift` - sidebar has Active and Archived sections only; remove completed section; remove milestone archive callback.
- Modify: `OneStep/Views/FinalGoalDetailView.swift` - remove all-milestones-done gate; remove separate archive action; complete/finish action sets final-goal `archivedAt`.
- Modify: `OneStep/Views/GoalRowView.swift` - remove milestone archive menu action; disable check-in for all non-current or completed milestones.
- Modify: `OneStepTests/GoalStoreTests.swift` - update store tests for single final-goal end state.

### Widget and Docs

- Modify: `OneStepWidget/CompleteGoalIntent.swift` - remove stale-tap catch for `milestoneGoalNotActive`; completed milestones become stale through `notCurrentMilestone`.
- Modify: `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md` - update source of truth for status fields and business rules.
- Modify: `docs/engineering/data-schema-and-migration.md`
- Modify: `docs/product/v1-product-spec.md`
- Modify: `docs/qa/release-checklist.md`

## Task 1: Domain State Fields

**Files:**
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/DomainTypeTests.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`

- [ ] **Step 1: Replace domain state tests**

In `DomainTypeTests.swift`, replace `testFinalGoalTracksActiveState` and `testMilestoneGoalTracksActiveState` with:

```swift
func testFinalGoalActiveStateOnlyDependsOnArchivedAt() {
    let goal = FinalGoal(title: "Pass IELTS", startDayKey: "2026-04-30", sortOrder: 0)
    XCTAssertTrue(goal.isActive)

    goal.archivedAt = Date()
    XCTAssertFalse(goal.isActive)
}

func testMilestoneGoalActiveStateOnlyDependsOnCompletedAt() {
    let milestone = MilestoneGoal(
        title: "Finish vocabulary",
        targetCompletionDays: 30,
        finalGoalID: UUID(),
        sortOrder: 0
    )
    XCTAssertTrue(milestone.isActive)

    milestone.completedAt = Date()
    XCTAssertFalse(milestone.isActive)
}
```

- [ ] **Step 2: Update snapshot tests to remove deleted fields**

In `DomainTypeTests.swift`, update `FinalGoalListSnapshot` initializers to omit `completedAt`, and update `MilestoneGoalSnapshot` initializers to omit `archivedAt`.

Final-goal snapshot initializer shape:

```swift
FinalGoalListSnapshot(
    id: id,
    title: "Pass IELTS",
    goalDescription: "Reach band 7",
    targetCalendarDays: 180,
    completedMilestoneCount: 1,
    totalMilestoneCount: 3,
    currentMilestoneID: milestoneID,
    currentMilestoneTitle: "Finish vocabulary",
    remainingCalendarDays: 120,
    sortOrder: 0,
    archivedAt: nil
)
```

Milestone snapshot initializer shape:

```swift
MilestoneGoalSnapshot(
    id: id,
    title: "Finish vocabulary",
    targetCompletionDays: 30,
    finalGoalID: finalGoalID,
    sortOrder: 0,
    isCurrent: true,
    completedDays: 12,
    remainingDays: 18,
    completionRate: 0.4,
    isCompletedToday: false,
    startDayKey: "2026-04-30",
    completedAt: nil,
    recentActivity: []
)
```

- [ ] **Step 3: Run domain tests to verify failure**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter DomainTypeTests
```

Expected: FAIL because `FinalGoal` still has `completedAt`, `MilestoneGoal` still has `archivedAt`, and snapshot initializer signatures still include removed fields.

- [ ] **Step 4: Remove `FinalGoal.completedAt`**

Edit `FinalGoal.swift` to this shape:

```swift
import Foundation
import SwiftData

@Model
public final class FinalGoal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var goalDescription: String?
    public var targetCalendarDays: Int?
    public var startDayKey: String
    public var sortOrder: Int
    public var archivedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String? = nil,
        targetCalendarDays: Int? = nil,
        startDayKey: String,
        sortOrder: Int,
        archivedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.startDayKey = startDayKey
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { archivedAt == nil }
}
```

- [ ] **Step 5: Remove `MilestoneGoal.archivedAt`**

Edit `MilestoneGoal.swift` to this shape:

```swift
import Foundation
import SwiftData

@Model
public final class MilestoneGoal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var targetCompletionDays: Int
    public var finalGoalID: UUID
    public var sortOrder: Int
    public var startDayKey: String?
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        targetCompletionDays: Int,
        finalGoalID: UUID,
        sortOrder: Int,
        startDayKey: String? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetCompletionDays = targetCompletionDays
        self.finalGoalID = finalGoalID
        self.sortOrder = sortOrder
        self.startDayKey = startDayKey
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { completedAt == nil }
}
```

- [ ] **Step 6: Update snapshots**

In `GoalSnapshots.swift`:

Remove from `FinalGoalListSnapshot`:

```swift
public let completedAt: Date?
```

Remove the matching initializer parameter and assignment:

```swift
completedAt: Date?
self.completedAt = completedAt
```

Remove from `MilestoneGoalSnapshot`:

```swift
public let archivedAt: Date?
```

Remove the matching initializer parameter and assignment:

```swift
archivedAt: Date?
self.archivedAt = archivedAt
```

- [ ] **Step 7: Run domain tests to verify pass**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter DomainTypeTests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift Packages/OneStepCore/Tests/OneStepCoreTests/DomainTypeTests.swift
git commit -m "refactor: simplify goal hierarchy status fields"
```

## Task 2: FinalGoal Repository Rules

**Files:**
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift`

- [ ] **Step 1: Replace final-goal completion tests**

In `FinalGoalRepositoryTests.swift`, delete these tests:

```swift
func testCompleteFinalGoalRejectsWhenMilestonesIncomplete() throws
func testCompleteFinalGoalSucceedsWhenAllMilestonesDone() throws
func testArchiveFinalGoalCascadesToIncompleteMilestones() throws
```

Add:

```swift
func testArchiveFinalGoalSetsOnlyFinalGoalArchivedAt() throws {
    let fixture = try makeFixture()
    let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
    let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
    _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

    try fixture.repository.archiveFinalGoal(finalGoalID: fgID, archivedAt: Date())

    let goal = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
    XCTAssertNotNil(goal.archivedAt)
    let milestones = try fixture.fetchMilestones(for: fgID)
    XCTAssertEqual(milestones.count, 1)
    XCTAssertNil(milestones[0].completedAt)
}

func testArchiveFinalGoalAllowsIncompleteMilestones() throws {
    let fixture = try makeFixture()
    let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
    let fgID = try fixture.createFinalGoal(title: "Goal", day: day)
    _ = try fixture.createMilestone(title: "Phase 1", targetDays: 5, finalGoalID: fgID)

    try fixture.repository.archiveFinalGoal(finalGoalID: fgID, archivedAt: Date())

    let snapshot = try XCTUnwrap(try fixture.repository.finalGoalsForList().first { $0.id == fgID })
    XCTAssertNotNil(snapshot.archivedAt)
}
```

- [ ] **Step 2: Update move and snapshot tests for no `completedAt`**

In `testMoveActiveFinalGoalReorders`, change active filtering from:

```swift
let activeIDs = snapshots.filter { $0.archivedAt == nil }.map(\.id)
```

Keep that same expression if already present, and remove any `completedAt` filtering in this file.

In `testFinalGoalsForListShowsMilestoneProgress`, keep the milestone `completedAt` manual setup, but assert only final-goal snapshot fields that still exist:

```swift
XCTAssertEqual(snapshot.completedMilestoneCount, 1)
XCTAssertEqual(snapshot.totalMilestoneCount, 2)
XCTAssertEqual(snapshot.currentMilestoneID, milestones.first { $0.id != m1 }?.id)
XCTAssertNil(snapshot.archivedAt)
```

- [ ] **Step 3: Run final-goal repository tests to verify failure**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter FinalGoalRepositoryTests
```

Expected: FAIL because repository code still references `FinalGoal.completedAt`, `MilestoneGoal.archivedAt`, `completeFinalGoal`, `milestonesIncomplete`, and `FinalGoalListSnapshot.completedAt`.

- [ ] **Step 4: Remove obsolete errors**

In `GoalRepositoryError.swift`, remove:

```swift
case milestoneGoalNotActive
case milestonesIncomplete
```

Remove their `errorDescription` switch branches:

```swift
case .milestoneGoalNotActive:
    return "Milestone goal is archived or completed."
case .milestonesIncomplete:
    return "All milestones must be completed before completing the final goal."
```

Change `.finalGoalNotActive` description to:

```swift
return "Final goal is archived."
```

- [ ] **Step 5: Simplify `archiveFinalGoal` and remove `completeFinalGoal`**

In `FinalGoalRepository.swift`, replace `archiveFinalGoal` with:

```swift
public func archiveFinalGoal(finalGoalID: UUID, archivedAt: Date) throws {
    let goal = try fetchFinalGoal(finalGoalID: finalGoalID)
    goal.archivedAt = archivedAt
    goal.updatedAt = Date()
    try save()
}
```

Delete the entire method:

```swift
public func completeFinalGoal(finalGoalID: UUID, completedAt: Date) throws
```

- [ ] **Step 6: Update active and snapshot logic**

In `FinalGoalRepository.swift`, keep active goals based on `goal.isActive`; after Task 1 this means `archivedAt == nil`.

In `makeListSnapshot(goal:)`, change:

```swift
let currentMilestone = milestones.first(where: { $0.isActive })
```

Keep that expression; after Task 1 it means `completedAt == nil`.

Remove the `completedAt` argument from `FinalGoalListSnapshot`:

```swift
return FinalGoalListSnapshot(
    id: goal.id,
    title: goal.title,
    goalDescription: goal.goalDescription,
    targetCalendarDays: goal.targetCalendarDays,
    completedMilestoneCount: completedMilestoneCount,
    totalMilestoneCount: totalMilestoneCount,
    currentMilestoneID: currentMilestone?.id,
    currentMilestoneTitle: currentMilestone?.title,
    remainingCalendarDays: remainingCalendarDays,
    sortOrder: goal.sortOrder,
    archivedAt: goal.archivedAt
)
```

- [ ] **Step 7: Run final-goal repository tests to verify pass**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter FinalGoalRepositoryTests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift
git commit -m "refactor: make final goal archive the end state"
```

## Task 3: Milestone Repository Rules

**Files:**
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/MilestoneGoalRepositoryTests.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift`
- Modify: `OneStepWidget/CompleteGoalIntent.swift`

- [ ] **Step 1: Replace milestone archive tests**

In `MilestoneGoalRepositoryTests.swift`, delete:

```swift
func testArchivingCurrentMakesNextCurrent() throws
```

Add:

```swift
func testCompletedCurrentMakesNextCurrent() throws {
    let fixture = try makeFixture()
    let fgID = try fixture.createFinalGoal()
    let m1 = try fixture.createMilestone(title: "Phase 1", targetDays: 1, finalGoalID: fgID)
    _ = try fixture.createMilestone(title: "Phase 2", targetDays: 5, finalGoalID: fgID)

    try fixture.repository.completeToday(milestoneGoalID: m1, day: fixture.day)

    let milestones = try fixture.repository.milestonesForFinalGoal(finalGoalID: fgID, day: fixture.day)
    XCTAssertNotNil(milestones[0].completedAt)
    XCTAssertFalse(milestones[0].isCurrent)
    XCTAssertTrue(milestones[1].isCurrent)
}
```

- [ ] **Step 2: Add widget limit regression test**

Add this test to `MilestoneGoalRepositoryTests.swift`:

```swift
func testActiveMilestonesForWidgetFillsLimitAfterGoalsWithoutCurrentMilestone() throws {
    let fixture = try makeFixture()
    let firstGoal = try fixture.createFinalGoal()
    let secondGoal = try fixture.createFinalGoal()
    let firstMilestone = try fixture.createMilestone(title: "Already done", targetDays: 1, finalGoalID: firstGoal)
    _ = try fixture.createMilestone(title: "Still active", targetDays: 5, finalGoalID: secondGoal)

    try fixture.repository.completeToday(milestoneGoalID: firstMilestone, day: fixture.day)

    let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 1, day: fixture.day)

    XCTAssertEqual(snapshots.map(\.title), ["Still active"])
}
```

- [ ] **Step 3: Update tests that complete final goals**

In `testActiveMilestonesForWidgetExcludesCompletedFinalGoals`, rename the test to:

```swift
func testActiveMilestonesForWidgetExcludesArchivedFinalGoals() throws
```

Use only `archiveFinalGoal`:

```swift
let fgRepo = FinalGoalRepository(modelContext: fixture.modelContext)
try fgRepo.archiveFinalGoal(finalGoalID: fgID, archivedAt: Date())

let snapshots = try fixture.repository.activeMilestonesForWidget(limit: 10, day: fixture.day)
XCTAssertEqual(snapshots.count, 0)
```

Delete the old manual milestone completion and `completeFinalGoal` call from that test.

- [ ] **Step 4: Run milestone repository tests to verify failure**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter MilestoneGoalRepositoryTests
```

Expected: FAIL because `archiveMilestoneGoal`, `milestone.archivedAt`, and `GoalRepositoryError.milestoneGoalNotActive` still exist or are referenced inconsistently.

- [ ] **Step 5: Remove milestone archive API and active guard**

In `MilestoneGoalRepository.swift`, delete:

```swift
public func archiveMilestoneGoal(milestoneGoalID: UUID, archivedAt: Date) throws
```

In `updateMilestoneGoal`, replace:

```swift
guard milestone.isActive else { throw GoalRepositoryError.milestoneGoalNotActive }
```

with:

```swift
guard milestone.completedAt == nil else { throw GoalRepositoryError.notCurrentMilestone }
```

In `completeToday`, replace:

```swift
guard milestone.isActive else { throw GoalRepositoryError.milestoneGoalNotActive }
```

with:

```swift
guard milestone.completedAt == nil else { throw GoalRepositoryError.notCurrentMilestone }
```

- [ ] **Step 6: Update milestone snapshots**

In `milestonesForFinalGoal`, remove `archivedAt` from snapshot creation:

```swift
return MilestoneGoalSnapshot(
    id: milestone.id,
    title: milestone.title,
    targetCompletionDays: milestone.targetCompletionDays,
    finalGoalID: milestone.finalGoalID,
    sortOrder: milestone.sortOrder,
    isCurrent: milestone.id == currentActiveID,
    completedDays: completedDays,
    remainingDays: remainingDays,
    completionRate: completionRate,
    isCompletedToday: isCompletedToday,
    startDayKey: milestone.startDayKey,
    completedAt: milestone.completedAt,
    recentActivity: (try? recentActivity(goalID: milestone.id, endingOn: day)) ?? []
)
```

- [ ] **Step 7: Fix widget limit after skipped goals**

In `activeMilestonesForWidget`, replace:

```swift
for finalGoal in activeFinalGoals.prefix(boundedLimit) {
    guard let current = try currentActiveMilestone(for: finalGoal.id) else { continue }
    let completedDays = try completedDays(for: current.id)
    snapshots.append(WidgetMilestoneSnapshot(
        id: current.id,
        title: current.title,
        parentFinalGoalTitle: finalGoal.title,
        targetCompletionDays: current.targetCompletionDays,
        completedDays: completedDays,
        isCompletedToday: try isCompleted(goalID: current.id, day: day)
    ))
}
return snapshots
```

with:

```swift
for finalGoal in activeFinalGoals {
    guard snapshots.count < boundedLimit else { break }
    guard let current = try currentActiveMilestone(for: finalGoal.id) else { continue }
    let completedDays = try completedDays(for: current.id)
    snapshots.append(WidgetMilestoneSnapshot(
        id: current.id,
        title: current.title,
        parentFinalGoalTitle: finalGoal.title,
        targetCompletionDays: current.targetCompletionDays,
        completedDays: completedDays,
        isCompletedToday: try isCompleted(goalID: current.id, day: day)
    ))
}
return snapshots
```

- [ ] **Step 8: Update widget stale-tap handling**

In `OneStepWidget/CompleteGoalIntent.swift`, remove this catch branch:

```swift
} catch GoalRepositoryError.milestoneGoalNotActive {
    OneStepLog.appIntent.error("Stale widget tap ignored because milestone was not active: \(goalID)")
```

Keep the `notCurrentMilestone` catch branch.

- [ ] **Step 9: Run milestone repository tests to verify pass**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter MilestoneGoalRepositoryTests
```

Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift Packages/OneStepCore/Tests/OneStepCoreTests/MilestoneGoalRepositoryTests.swift OneStepWidget/CompleteGoalIntent.swift
git commit -m "refactor: remove milestone archive state"
```

## Task 4: App Stores and Views

**Files:**
- Modify: `OneStepTests/GoalStoreTests.swift`
- Modify: `OneStep/App/FinalGoalStore.swift`
- Modify: `OneStep/App/MilestoneGoalStore.swift`
- Modify: `OneStep/Views/GoalListView.swift`
- Modify: `OneStep/Views/FinalGoalDetailView.swift`
- Modify: `OneStep/Views/GoalRowView.swift`

- [ ] **Step 1: Update store tests**

In `GoalStoreTests.swift`, replace `testCompleteArchiveAndMoveRefreshListState` with:

```swift
func testCompleteFinalGoalArchivesItAndRefreshesListState() throws {
    let fixture = try makeFixture()
    fixture.store.createFinalGoal(title: "First", goalDescription: nil, targetCalendarDays: nil)
    fixture.store.createFinalGoal(title: "Second", goalDescription: nil, targetCalendarDays: nil)
    let firstID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "First" }?.id)
    let secondID = try XCTUnwrap(fixture.store.finalGoals.first { $0.title == "Second" }?.id)

    fixture.store.completeFinalGoal(finalGoalID: firstID)
    XCTAssertNotNil(fixture.store.finalGoals.first { $0.id == firstID }?.archivedAt)

    fixture.store.move(from: IndexSet(integer: 1), to: 0)
    let activeGoals = fixture.store.finalGoals.filter { $0.archivedAt == nil }
    XCTAssertEqual(activeGoals.map(\.id), [secondID])
}
```

In `MilestoneGoalStoreTests`, do not add archive tests; milestone store should no longer expose archive.

- [ ] **Step 2: Run app tests to verify failure**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' -only-testing:OneStepTests
```

Expected: FAIL because app code still references removed snapshot fields and milestone archive APIs.

- [ ] **Step 3: Update `FinalGoalStore`**

In `FinalGoalStore.swift`, change active filters from:

```swift
$0.archivedAt == nil && $0.completedAt == nil
```

to:

```swift
$0.archivedAt == nil
```

Replace `completeFinalGoal` implementation with:

```swift
func completeFinalGoal(finalGoalID: UUID) {
    do {
        try repository.archiveFinalGoal(finalGoalID: finalGoalID, archivedAt: Date())
        refreshAndReloadWidget()
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

Keep `archiveFinalGoal(finalGoalID:)` as a separate method only if the UI still has a second archive command. If the UI has only one end-state command, delete `archiveFinalGoal(finalGoalID:)` from the store.

- [ ] **Step 4: Update `MilestoneGoalStore`**

Delete:

```swift
func archiveMilestone(milestoneGoalID: UUID, finalGoalID: UUID)
```

- [ ] **Step 5: Update sidebar sections**

In `GoalListView.swift`, replace section computed properties with:

```swift
private var activeGoals: [FinalGoalListSnapshot] {
    finalGoalStore.finalGoals.filter { $0.archivedAt == nil }
}

private var archivedGoals: [FinalGoalListSnapshot] {
    finalGoalStore.finalGoals.filter { $0.archivedAt != nil }
}
```

Delete the `completedGoals` computed property and the `Completed` section.

Remove `onArchiveMilestone` from `FinalGoalDetailView` construction.

- [ ] **Step 6: Update final-goal detail actions**

In `FinalGoalDetailView.swift`, remove:

```swift
let onArchive: () -> Void
let onArchiveMilestone: (UUID) -> Void
private var activeMilestones: [MilestoneGoalSnapshot] { ... }
private var allMilestonesDone: Bool { ... }
```

Replace the menu end-state actions with one command:

```swift
Button("Complete Goal", action: onComplete)
    .disabled(goal.archivedAt != nil)
```

Render all milestones:

```swift
ForEach(milestones) { milestone in
    MilestoneGoalRowView(
        milestone: milestone,
        onCheckIn: { onCheckIn(milestone.id) },
        onUndo: { onUndo(milestone.id) },
        onEdit: { onEditMilestone(milestone) }
    )
}
```

- [ ] **Step 7: Update milestone row**

In `GoalRowView.swift`, change `MilestoneGoalRowView` stored properties to:

```swift
let milestone: MilestoneGoalSnapshot
let onCheckIn: () -> Void
let onUndo: () -> Void
let onEdit: () -> Void
```

Change button disabling to:

```swift
.disabled(!milestone.isCurrent || milestone.completedAt != nil)
```

Delete the archive menu action:

```swift
Button("Archive", role: .destructive, action: onArchive)
    .disabled(milestone.archivedAt != nil)
```

Keep only:

```swift
Menu {
    Button("Edit", action: onEdit)
} label: {
    Image(systemName: "ellipsis.circle")
}
.menuStyle(.button)
.frame(width: 32)
```

- [ ] **Step 8: Run app tests to verify pass**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' -only-testing:OneStepTests
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add OneStep/App/FinalGoalStore.swift OneStep/App/MilestoneGoalStore.swift OneStep/Views/GoalListView.swift OneStep/Views/FinalGoalDetailView.swift OneStep/Views/GoalRowView.swift OneStepTests/GoalStoreTests.swift
git commit -m "refactor: align app with simplified goal states"
```

## Task 5: Documentation Updates

**Files:**
- Modify: `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`
- Modify: `docs/engineering/data-schema-and-migration.md`
- Modify: `docs/product/v1-product-spec.md`
- Modify: `docs/qa/release-checklist.md`

- [ ] **Step 1: Update design doc data model**

In `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`, remove `completedAt` from the `FinalGoal` table and set:

```markdown
Computed: `isActive` = `archivedAt == nil`
```

Remove `archivedAt` from the `MilestoneGoal` table and set:

```markdown
Computed: `isActive` = `completedAt == nil`
```

- [ ] **Step 2: Update design doc business rules**

Replace the completion and archival sections with:

```markdown
### FinalGoal Completion / Archival

- Completing a FinalGoal and archiving a FinalGoal are the same state transition.
- The user can complete/archive a FinalGoal at any time.
- Completing/archiveing sets `FinalGoal.archivedAt`.
- Archived FinalGoals are removed from the active list and do not contribute milestones to the widget.
- Completing/archiveing a FinalGoal does not mutate its MilestoneGoals.

### Milestone Completion

- MilestoneGoals cannot be archived independently.
- A MilestoneGoal completes when `completedDays >= targetCompletionDays`.
- Completing a MilestoneGoal sets `MilestoneGoal.completedAt`.
- The current active milestone is the first MilestoneGoal by `sortOrder` where `completedAt == nil`.
```

Replace check-in rules with:

```markdown
- One check-in per MilestoneGoal per day.
- Only the current active milestone of an active FinalGoal can receive check-ins.
- Completed milestones cannot receive new check-ins.
- Undo (app only): delete today's `DailyCompletion` for a milestone.
```

- [ ] **Step 3: Update engineering schema docs**

In `docs/engineering/data-schema-and-migration.md`, document:

```markdown
`FinalGoal` stores the long-term aspiration. Its only lifecycle status field is `archivedAt`; setting it means the goal is complete/ended/archived and should not appear in active workflows.

`MilestoneGoal` stores one ordered phase under a final goal. Its only lifecycle status field is `completedAt`; it has no archive state.
```

- [ ] **Step 4: Update product spec and QA checklist**

In `docs/product/v1-product-spec.md`, state:

```markdown
A final goal can be completed at any time. Completing a final goal removes it from active tracking and the widget. Milestones are not archived; they are either incomplete or complete.
```

In `docs/qa/release-checklist.md`, add manual checks:

```markdown
- Complete a final goal with no milestones and verify it leaves the active list.
- Complete a final goal with incomplete milestones and verify it leaves the active list.
- Verify completing a final goal does not mark its milestones complete.
- Verify milestones have no archive action.
- Complete the current milestone and verify the next incomplete milestone becomes current.
- Verify widget skips archived final goals and shows the next active final goal with a current milestone.
```

- [ ] **Step 5: Run documentation unresolved-marker scan**

Run:

```bash
rg -n "T[O]DO|T[B]D|fill[[:space:]]in" docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
git commit -m "docs: define simplified goal status model"
```

## Task 6: Final Verification and Cleanup

**Files:**
- Validate: `Packages/OneStepCore`
- Validate: `OneStep`
- Validate: `OneStepWidget`
- Validate: `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`
- Validate: `docs/engineering/data-schema-and-migration.md`
- Validate: `docs/product/v1-product-spec.md`
- Validate: `docs/qa/release-checklist.md`

- [ ] **Step 1: Search for obsolete status fields and APIs**

Run:

```bash
rg -n "FinalGoal\\.completedAt|goal\\.completedAt|completedAt: Date\\? = nil,\\n\\s*archivedAt|MilestoneGoal\\.archivedAt|milestone\\.archivedAt|archiveMilestone|milestoneGoalNotActive|milestonesIncomplete|allMilestonesDone|completedGoals" Packages/OneStepCore OneStep OneStepWidget OneStepTests docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md
```

Expected: no output.

- [ ] **Step 2: Search for allowed status references**

Run:

```bash
rg -n "archivedAt|completedAt" Packages/OneStepCore/Sources/OneStepCore OneStep OneStepWidget
```

Expected:

- `FinalGoal` and `FinalGoalListSnapshot` may reference `archivedAt`.
- `MilestoneGoal`, `MilestoneGoalSnapshot`, `DailyCompletion`, milestone repository, milestone rows, and widget snapshots may reference `completedAt`.
- No `FinalGoal.completedAt`.
- No `MilestoneGoal.archivedAt`.

- [ ] **Step 3: Run core tests**

Run:

```bash
swift test --package-path Packages/OneStepCore
```

Expected: PASS.

- [ ] **Step 4: Run app tests**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 5: Build widget**

Run:

```bash
xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 6: Run final unresolved-marker scan**

Run:

```bash
rg -n "T[O]DO|T[B]D|fill[[:space:]]in" Packages/OneStepCore OneStep OneStepWidget OneStepTests docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
```

Expected: no output.

- [ ] **Step 7: Manual app smoke check**

In the running macOS app:

```text
1. Create "Pass IELTS" as a final goal.
2. Add milestones "Finish vocabulary" with target 1 and "Practice listening" with target 1.
3. Verify only "Finish vocabulary" exposes check-in.
4. Verify there is no archive action on either milestone row.
5. Choose "Complete Goal" before completing any milestone.
6. Verify the final goal leaves the active sidebar list and appears only in archived/history UI if that UI is visible.
7. Create a second final goal with two milestones.
8. Check in the first milestone and verify the second milestone becomes current.
```

- [ ] **Step 8: Manual widget smoke check**

With the widget installed:

```text
1. Create two active final goals with one milestone each.
2. Complete/archive the first final goal from the app.
3. Verify the widget no longer shows the first final goal's milestone.
4. Verify the widget shows the second final goal's current milestone.
5. Tap the widget row and verify today's completion appears in the app.
6. Verify repeated tapping does not create duplicate completions.
```

- [ ] **Step 9: Commit verification fixes only if needed**

If verification required fixes:

```bash
git add Packages/OneStepCore OneStep OneStepWidget OneStepTests docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
git commit -m "chore: verify simplified goal status model"
```

If no fixes were required, do not create an empty commit.

## Self-Review

### Spec Coverage

- `FinalGoal` only has `archivedAt` as lifecycle status: Task 1, Task 2, Task 5.
- `MilestoneGoal` only has `completedAt` as lifecycle status: Task 1, Task 3, Task 5.
- Completing a final goal is equivalent to archiving: Task 2, Task 4, Task 5.
- Final-goal completion does not depend on milestone completion: Task 2 and Task 4.
- Milestones cannot be archived independently: Task 3 and Task 4.
- Current milestone advances by first incomplete milestone: Task 1 and Task 3.
- Widget excludes archived final goals and fills limit after skipped goals: Task 3 and Task 6.
- App UI removes milestone archive action and milestone completion gate for final goals: Task 4.
- Docs and QA reflect the simplified state model: Task 5.

### Placeholder Scan

The plan contains no unresolved placeholder markers. Every code-changing step includes the exact target file and concrete code or deletion instructions.

### Type Consistency

Final names used consistently:

- `FinalGoal.archivedAt`
- `FinalGoal.isActive == archivedAt == nil`
- `MilestoneGoal.completedAt`
- `MilestoneGoal.isActive == completedAt == nil`
- `FinalGoalListSnapshot.archivedAt`
- `MilestoneGoalSnapshot.completedAt`
- `FinalGoalRepository.archiveFinalGoal(finalGoalID:archivedAt:)`
- No `FinalGoal.completedAt`
- No `MilestoneGoal.archivedAt`
- No `archiveMilestoneGoal`
