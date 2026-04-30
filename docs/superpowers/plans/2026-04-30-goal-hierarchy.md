# Goal Hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat `Goal` model with ordered `FinalGoal` and `MilestoneGoal` models so daily check-ins happen against the current active milestone for each long-term goal.

**Architecture:** Keep persistence and business rules in `OneStepCore`, expose UI-ready immutable snapshots, and keep the app/widget layers rendering those snapshots. `FinalGoalRepository` owns final-goal lifecycle, manual completion, archive, reorder, and cascade deletion; `MilestoneGoalRepository` owns milestone CRUD, check-ins, undo, activity, auto-completion, and widget active-milestone queries.

**Tech Stack:** macOS SwiftUI, SwiftData, Observation, WidgetKit, AppIntents, XCTest, `OneStepCore`.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`
- Current core model: `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`
- Current completion model: `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`
- Current repository: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift`
- Current snapshots: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`
- Current app store: `OneStep/App/GoalStore.swift`
- Current app shell: `OneStep/Views/ContentView.swift`
- Current widget flow: `OneStepWidget/OneStepTimelineProvider.swift`, `OneStepWidget/CompleteGoalIntent.swift`, `OneStepWidget/WidgetGoalRowView.swift`

## Scope Check

This spec touches core data, app UI, widget UI, and documentation, but all changes are one connected feature: the app cannot ship the hierarchy without the shared schema, the app cannot render current milestones without the repositories, and the widget must target the same milestone check-in rules. Keep this as one implementation plan with small, independently testable tasks.

No old data migration is implemented. The project is pre-v1.0, so the schema starts fresh with `FinalGoal`, `MilestoneGoal`, and `DailyCompletion`.

## File Map

### Core Package

- Delete: `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift` - removed flat model.
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift` - long-term aspiration model.
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift` - ordered phase model.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift` - `goalID` now stores a `MilestoneGoal.id`; field name stays unchanged.
- Delete: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift` - replaced by two focused repositories.
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift` - final-goal CRUD, archive, reorder, completion, delete.
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift` - milestone CRUD, check-in, undo, archive, delete, widget snapshots.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift` - new hierarchy-specific errors.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift` - replace flat goal snapshots and input structs.
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift` - register `FinalGoal`, `MilestoneGoal`, and `DailyCompletion`.
- Delete: `Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryTests.swift`
- Delete: `Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryCompletionTests.swift`
- Create: `Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift`
- Create: `Packages/OneStepCore/Tests/OneStepCoreTests/MilestoneGoalRepositoryTests.swift`

### App Target

- Delete: `OneStep/App/GoalStore.swift`
- Create: `OneStep/App/FinalGoalStore.swift` - final-goal list, selection helpers, CRUD, reorder, archive, manual completion.
- Create: `OneStep/App/MilestoneGoalStore.swift` - selected final-goal milestones, milestone CRUD, check-in, undo, archive.
- Modify: `OneStep/Views/ContentView.swift` - initialize both stores and present final-goal creation.
- Modify: `OneStep/Views/GoalListView.swift` - make the sidebar the final-goal list and the detail pane the selected final goal.
- Create: `OneStep/Views/FinalGoalDetailView.swift` - editable final-goal header, ordered milestone list, add milestone, complete final goal.
- Modify: `OneStep/Views/GoalRowView.swift` - split content into `FinalGoalRowView` and `MilestoneGoalRowView` in this file to keep Xcode project churn small.
- Modify: `OneStep/Views/GoalEditorView.swift` - replace with `FinalGoalEditorView` and `MilestoneGoalEditorView` in this file.
- Modify: `OneStep/Views/EmptyStateView.swift` - text updates only.
- Keep: `OneStep/Views/RecentActivityView.swift` - still renders `[RecentActivityDay]`.
- Modify: `OneStepTests/GoalStoreTests.swift` - replace tests with `FinalGoalStoreTests` and `MilestoneGoalStoreTests` classes in the same file.

### Widget Target

- Modify: `OneStepWidget/OneStepTimelineProvider.swift` - load active milestone snapshots.
- Modify: `OneStepWidget/OneStepWidget.swift` - empty text and snapshot naming.
- Modify: `OneStepWidget/CompleteGoalIntent.swift` - parameter still named `goalID` for AppIntent compatibility, but it targets `MilestoneGoal.id`.
- Modify: `OneStepWidget/WidgetGoalRowView.swift` - render milestone title plus parent final-goal title.

### Xcode Project and Docs

- Modify: `OneStep.xcodeproj/project.pbxproj` - remove deleted app files from build phases, add new app files to target build phases.
- Modify: `docs/engineering/data-schema-and-migration.md` - document new destructive pre-v1 schema.
- Modify: `docs/product/v1-product-spec.md` - update product behavior to final goals and milestones.
- Modify: `docs/qa/release-checklist.md` - update manual QA for milestone advancement and widget active milestones.

## Execution Order

1. Replace core model contracts and snapshots.
2. Implement `FinalGoalRepository`.
3. Implement `MilestoneGoalRepository`.
4. Update app stores and store tests.
5. Update SwiftUI views and Xcode project references.
6. Update widget timeline, intent, and row view.
7. Update docs.
8. Run package tests, Xcode tests, widget build, unresolved-marker scan, and manual smoke checks.

## Task 1: Core Models, Snapshots, and Schema

**Files:**
- Delete: `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift`
- Modify: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift`
- Test: `Packages/OneStepCore/Tests/OneStepCoreTests/DomainTypeTests.swift`

- [ ] **Step 1: Add failing schema and domain tests**

Add these tests to `DomainTypeTests.swift`:

```swift
@MainActor
func testModelContainerUsesGoalHierarchyModels() throws {
    let container = try OneStepModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let finalGoal = FinalGoal(
        title: "Pass IELTS",
        goalDescription: "Reach band 7",
        targetCalendarDays: 180,
        startDayKey: "2026-04-30",
        sortOrder: 0
    )
    let milestone = MilestoneGoal(
        title: "Finish vocabulary",
        targetCompletionDays: 30,
        finalGoalID: finalGoal.id,
        sortOrder: 0
    )

    context.insert(finalGoal)
    context.insert(milestone)
    try context.save()

    XCTAssertEqual(try context.fetch(FetchDescriptor<FinalGoal>()).map(\.title), ["Pass IELTS"])
    XCTAssertEqual(try context.fetch(FetchDescriptor<MilestoneGoal>()).map(\.title), ["Finish vocabulary"])
}

func testHierarchyInputTypesPreserveValues() throws {
    let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-30"))
    let finalID = UUID()

    let finalInput = CreateFinalGoalInput(
        title: "Pass IELTS",
        goalDescription: "Reach band 7",
        targetCalendarDays: 180,
        startDay: day
    )
    let milestoneInput = CreateMilestoneGoalInput(
        finalGoalID: finalID,
        title: "Finish vocabulary",
        targetCompletionDays: 30
    )

    XCTAssertEqual(finalInput.title, "Pass IELTS")
    XCTAssertEqual(finalInput.goalDescription, "Reach band 7")
    XCTAssertEqual(finalInput.targetCalendarDays, 180)
    XCTAssertEqual(finalInput.startDay, day)
    XCTAssertEqual(milestoneInput.finalGoalID, finalID)
    XCTAssertEqual(milestoneInput.title, "Finish vocabulary")
    XCTAssertEqual(milestoneInput.targetCompletionDays, 30)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter DomainTypeTests
```

Expected: FAIL because `FinalGoal`, `MilestoneGoal`, `CreateFinalGoalInput`, and `CreateMilestoneGoalInput` do not exist.

- [ ] **Step 3: Create `FinalGoal.swift`**

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
    public var completedAt: Date?
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
        completedAt: Date? = nil,
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
        self.completedAt = completedAt
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { archivedAt == nil && completedAt == nil }
}
```

- [ ] **Step 4: Create `MilestoneGoal.swift`**

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
    public var archivedAt: Date?
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
        archivedAt: Date? = nil,
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
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { archivedAt == nil && completedAt == nil }
}
```

- [ ] **Step 5: Replace snapshot and input contracts**

Replace `GoalSnapshots.swift` with these public contracts:

```swift
import Foundation

public struct CreateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let startDay: LocalDay

    public init(title: String, goalDescription: String?, targetCalendarDays: Int?, startDay: LocalDay) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.startDay = startDay
    }
}

public struct UpdateFinalGoalInput: Equatable, Sendable {
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?

    public init(title: String, goalDescription: String?, targetCalendarDays: Int?) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
    }
}

public struct CreateMilestoneGoalInput: Equatable, Sendable {
    public let finalGoalID: UUID
    public let title: String
    public let targetCompletionDays: Int

    public init(finalGoalID: UUID, title: String, targetCompletionDays: Int) {
        self.finalGoalID = finalGoalID
        self.title = title
        self.targetCompletionDays = targetCompletionDays
    }
}

public struct UpdateMilestoneGoalInput: Equatable, Sendable {
    public let title: String
    public let targetCompletionDays: Int

    public init(title: String, targetCompletionDays: Int) {
        self.title = title
        self.targetCompletionDays = targetCompletionDays
    }
}

public struct FinalGoalListSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let goalDescription: String?
    public let targetCalendarDays: Int?
    public let startDayKey: String
    public let completedMilestoneCount: Int
    public let totalMilestoneCount: Int
    public let currentMilestoneID: UUID?
    public let currentMilestoneTitle: String?
    public let remainingCalendarDays: Int?
    public let sortOrder: Int
    public let completedAt: Date?
    public let archivedAt: Date?

    public init(
        id: UUID,
        title: String,
        goalDescription: String?,
        targetCalendarDays: Int?,
        startDayKey: String,
        completedMilestoneCount: Int,
        totalMilestoneCount: Int,
        currentMilestoneID: UUID?,
        currentMilestoneTitle: String?,
        remainingCalendarDays: Int?,
        sortOrder: Int,
        completedAt: Date?,
        archivedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetCalendarDays = targetCalendarDays
        self.startDayKey = startDayKey
        self.completedMilestoneCount = completedMilestoneCount
        self.totalMilestoneCount = totalMilestoneCount
        self.currentMilestoneID = currentMilestoneID
        self.currentMilestoneTitle = currentMilestoneTitle
        self.remainingCalendarDays = remainingCalendarDays
        self.sortOrder = sortOrder
        self.completedAt = completedAt
        self.archivedAt = archivedAt
    }
}

public struct MilestoneGoalSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let finalGoalID: UUID
    public let title: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let remainingDays: Int
    public let completionRate: Double
    public let isCompletedToday: Bool
    public let isCurrent: Bool
    public let sortOrder: Int
    public let startDayKey: String?
    public let completedAt: Date?
    public let archivedAt: Date?
    public let recentActivity: [RecentActivityDay]

    public init(
        id: UUID,
        finalGoalID: UUID,
        title: String,
        targetCompletionDays: Int,
        completedDays: Int,
        remainingDays: Int,
        completionRate: Double,
        isCompletedToday: Bool,
        isCurrent: Bool,
        sortOrder: Int,
        startDayKey: String?,
        completedAt: Date?,
        archivedAt: Date?,
        recentActivity: [RecentActivityDay]
    ) {
        self.id = id
        self.finalGoalID = finalGoalID
        self.title = title
        self.targetCompletionDays = targetCompletionDays
        self.completedDays = completedDays
        self.remainingDays = remainingDays
        self.completionRate = completionRate
        self.isCompletedToday = isCompletedToday
        self.isCurrent = isCurrent
        self.sortOrder = sortOrder
        self.startDayKey = startDayKey
        self.completedAt = completedAt
        self.archivedAt = archivedAt
        self.recentActivity = recentActivity
    }
}

public struct WidgetMilestoneSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let finalGoalID: UUID
    public let title: String
    public let parentTitle: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let isCompletedToday: Bool

    public init(
        id: UUID,
        finalGoalID: UUID,
        title: String,
        parentTitle: String,
        targetCompletionDays: Int,
        completedDays: Int,
        isCompletedToday: Bool
    ) {
        self.id = id
        self.finalGoalID = finalGoalID
        self.title = title
        self.parentTitle = parentTitle
        self.targetCompletionDays = targetCompletionDays
        self.completedDays = completedDays
        self.isCompletedToday = isCompletedToday
    }
}

public struct RecentActivityDay: Identifiable, Equatable, Sendable {
    public var id: String { day.rawValue }
    public let day: LocalDay
    public let isCompleted: Bool

    public init(day: LocalDay, isCompleted: Bool) {
        self.day = day
        self.isCompleted = isCompleted
    }
}
```

- [ ] **Step 6: Update schema registration**

In `OneStepModelContainerFactory.swift`, change both schema definitions to:

```swift
let schema = Schema([FinalGoal.self, MilestoneGoal.self, DailyCompletion.self])
```

- [ ] **Step 7: Update errors**

Replace `GoalRepositoryError` cases with:

```swift
case finalGoalNotFound
case milestoneGoalNotFound
case finalGoalNotActive
case milestoneGoalNotActive
case invalidTitle
case invalidTargetCalendarDays
case invalidTargetCompletionDays
case targetBelowCompletedCount
case notCurrentMilestone
case milestonesIncomplete
case storeUnavailable
case saveFailed(String)
```

Use user-facing descriptions:

```swift
"Final goal not found."
"Milestone goal not found."
"Final goal is archived or completed."
"Milestone goal is archived or completed."
"Goal title is required."
"Target calendar days must be greater than zero."
"Target completion days must be greater than zero."
"Target completion days cannot be below completed days."
"Only the current active milestone can be completed."
"Complete all milestones before completing the final goal."
"Shared store is unavailable."
"Save failed: \(message)"
```

- [ ] **Step 8: Update `DailyCompletion.swift` comments only**

Keep the public field names unchanged. Add this comment above `goalID`:

```swift
// Stores MilestoneGoal.id. The name stays goalID to preserve the widget intent and unique-key API shape.
public var goalID: UUID
```

- [ ] **Step 9: Delete the old flat model**

Remove `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`.

- [ ] **Step 10: Run tests**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter DomainTypeTests
```

Expected: PASS for `DomainTypeTests`; other repository tests may fail until later tasks remove or replace them.

- [ ] **Step 11: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Models Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift Packages/OneStepCore/Tests/OneStepCoreTests/DomainTypeTests.swift
git commit -m "feat: add goal hierarchy core models"
```

## Task 2: FinalGoalRepository

**Files:**
- Delete: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/FinalGoalRepository.swift`
- Delete: `Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryTests.swift`
- Delete: `Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryCompletionTests.swift`
- Create: `Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift`

- [ ] **Step 1: Write failing final-goal repository tests**

Create `FinalGoalRepositoryTests.swift` with tests named:

```swift
func testCreateFinalGoalAcceptsValidDataAndTrimsStrings() throws
func testCreateFinalGoalRejectsEmptyTitle() throws
func testCreateFinalGoalRejectsInvalidCalendarLimit() throws
func testUpdateFinalGoalAppliesTrimmedValues() throws
func testMoveActiveFinalGoalChangesActiveOrderOnly() throws
func testArchiveFinalGoalArchivesIncompleteMilestones() throws
func testCompleteFinalGoalRequiresAllMilestonesComplete() throws
func testCompleteFinalGoalSetsCompletedAtWhenAllMilestonesDone() throws
func testDeleteFinalGoalDeletesMilestonesAndCompletions() throws
func testFinalGoalsForListShowsMilestoneProgressCurrentMilestoneAndCountdown() throws
```

Use this fixture shape:

```swift
@MainActor
private struct FinalGoalRepositoryFixture {
    let modelContext: ModelContext
    let finalGoals: FinalGoalRepository
    let milestones: MilestoneGoalRepository

    func createFinalGoal(title: String = "Pass IELTS", day: LocalDay) throws -> UUID {
        try finalGoals.createFinalGoal(CreateFinalGoalInput(
            title: title,
            goalDescription: "Reach band 7",
            targetCalendarDays: 180,
            startDay: day
        ))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter FinalGoalRepositoryTests
```

Expected: FAIL because `FinalGoalRepository` does not exist.

- [ ] **Step 3: Implement repository public API**

Create `FinalGoalRepository.swift` with this public surface:

```swift
@MainActor
public struct FinalGoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> FinalGoalRepository {
        let container = try OneStepModelContainerFactory.makeShared(appGroupIdentifier: appGroupIdentifier)
        return FinalGoalRepository(modelContext: ModelContext(container))
    }

    public func createFinalGoal(_ input: CreateFinalGoalInput) throws -> UUID
    public func updateFinalGoal(finalGoalID: UUID, input: UpdateFinalGoalInput) throws
    public func archiveFinalGoal(finalGoalID: UUID, archivedAt: Date) throws
    public func deleteFinalGoal(finalGoalID: UUID) throws
    public func moveActiveFinalGoal(finalGoalID: UUID, toIndex: Int) throws
    public func completeFinalGoal(finalGoalID: UUID, completedAt: Date) throws
    public func finalGoalsForList(day: LocalDay) throws -> [FinalGoalListSnapshot]
}
```

- [ ] **Step 4: Implement final-goal creation and validation**

Rules:

```swift
func validateTitle(_ title: String) throws -> String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw GoalRepositoryError.invalidTitle }
    return trimmed
}

func validateGoalDescription(_ goalDescription: String?) -> String? {
    let trimmed = goalDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == true ? nil : trimmed
}

func validateTargetCalendarDays(_ value: Int?) throws {
    guard let value else { return }
    guard value > 0 else { throw GoalRepositoryError.invalidTargetCalendarDays }
}
```

Creation should set:

```swift
title: trimmedTitle
goalDescription: trimmedDescription
targetCalendarDays: input.targetCalendarDays
startDayKey: input.startDay.rawValue
sortOrder: try nextFinalGoalSortOrder()
```

- [ ] **Step 5: Implement list snapshots**

Snapshot rules:

```swift
let milestones = try fetchMilestones(finalGoalID: finalGoal.id)
let activeMilestones = milestones.filter(\.isActive)
let currentMilestone = activeMilestones.sorted { $0.sortOrder < $1.sortOrder }.first
let completedCount = milestones.filter { $0.completedAt != nil }.count
let remainingCalendarDays = try remainingCalendarDays(for: finalGoal, on: day)
```

Countdown calculation:

```swift
func remainingCalendarDays(for finalGoal: FinalGoal, on day: LocalDay) throws -> Int? {
    guard let target = finalGoal.targetCalendarDays else { return nil }
    guard let start = dayDateFormatter.date(from: finalGoal.startDayKey),
          let current = dayDateFormatter.date(from: day.rawValue) else {
        return nil
    }
    let elapsed = Calendar(identifier: .gregorian).dateComponents([.day], from: start, to: current).day ?? 0
    return target - elapsed
}
```

Do not clamp negative values; the spec says the countdown is motivational and does not block when exceeded.

- [ ] **Step 6: Implement archive, completion, delete, and move**

Archive behavior:

```swift
finalGoal.archivedAt = archivedAt
finalGoal.updatedAt = Date()
for milestone in try fetchMilestones(finalGoalID: finalGoalID) where milestone.completedAt == nil {
    milestone.archivedAt = archivedAt
    milestone.updatedAt = Date()
}
```

Manual completion behavior:

```swift
let milestones = try fetchMilestones(finalGoalID: finalGoalID)
guard milestones.allSatisfy({ $0.completedAt != nil }) else {
    throw GoalRepositoryError.milestonesIncomplete
}
finalGoal.completedAt = completedAt
finalGoal.updatedAt = Date()
```

Delete behavior:

```swift
for milestone in try fetchMilestones(finalGoalID: finalGoalID) {
    for completion in try fetchCompletions(goalID: milestone.id) {
        modelContext.delete(completion)
    }
    modelContext.delete(milestone)
}
modelContext.delete(finalGoal)
```

Move behavior should match the old active-goal move logic, but use active final goals where `archivedAt == nil && completedAt == nil`.

- [ ] **Step 7: Remove obsolete repository tests and old repository**

Delete:

```text
Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift
Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryTests.swift
Packages/OneStepCore/Tests/OneStepCoreTests/GoalRepositoryCompletionTests.swift
```

- [ ] **Step 8: Run final-goal tests**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter FinalGoalRepositoryTests
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Repositories Packages/OneStepCore/Tests/OneStepCoreTests
git commit -m "feat: add final goal repository"
```

## Task 3: MilestoneGoalRepository

**Files:**
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift`
- Create: `Packages/OneStepCore/Tests/OneStepCoreTests/MilestoneGoalRepositoryTests.swift`
- Modify: `Packages/OneStepCore/Tests/OneStepCoreTests/FinalGoalRepositoryTests.swift`

- [ ] **Step 1: Write failing milestone repository tests**

Create `MilestoneGoalRepositoryTests.swift` with tests named:

```swift
func testCreateMilestoneAppendsSortOrderWithinFinalGoal() throws
func testCreateMilestoneRejectsMissingFinalGoal() throws
func testCreateMilestoneRejectsInvalidTargetCompletionDays() throws
func testMilestonesForFinalGoalMarksOnlyFirstActiveMilestoneCurrent() throws
func testCompleteTodayAllowsOnlyCurrentActiveMilestone() throws
func testCompleteTodaySetsStartDayKeyOnFirstCompletionOnly() throws
func testCompleteTodayIsIdempotentPerMilestoneAndDay() throws
func testCompleteTodayAutoCompletesMilestoneAtTarget() throws
func testCompletingFirstMilestoneActivatesSecondMilestone() throws
func testUncompleteTodayReopensMilestoneIfTargetNoLongerMet() throws
func testArchiveCurrentMilestoneMakesNextIncompleteMilestoneCurrent() throws
func testDeleteMilestoneDeletesItsCompletions() throws
func testActiveMilestonesForWidgetReturnsOneCurrentMilestonePerActiveFinalGoal() throws
func testActiveMilestonesForWidgetExcludesCompletedAndArchivedFinalGoals() throws
func testActiveMilestonesForWidgetTreatsNegativeLimitAsEmpty() throws
func testRecentActivityIncludesThirtyDaysEndingOnRequestedDay() throws
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter MilestoneGoalRepositoryTests
```

Expected: FAIL because `MilestoneGoalRepository` does not exist or has no implementation.

- [ ] **Step 3: Implement repository public API**

Create `MilestoneGoalRepository.swift` with this public surface:

```swift
@MainActor
public struct MilestoneGoalRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public static func shared(appGroupIdentifier: String) throws -> MilestoneGoalRepository {
        let container = try OneStepModelContainerFactory.makeShared(appGroupIdentifier: appGroupIdentifier)
        return MilestoneGoalRepository(modelContext: ModelContext(container))
    }

    public func createMilestoneGoal(_ input: CreateMilestoneGoalInput) throws -> UUID
    public func updateMilestoneGoal(milestoneGoalID: UUID, input: UpdateMilestoneGoalInput) throws
    public func archiveMilestoneGoal(milestoneGoalID: UUID, archivedAt: Date) throws
    public func deleteMilestoneGoal(milestoneGoalID: UUID) throws
    public func completeToday(milestoneGoalID: UUID, day: LocalDay) throws
    public func uncompleteToday(milestoneGoalID: UUID, day: LocalDay) throws
    public func milestonesForFinalGoal(finalGoalID: UUID, day: LocalDay) throws -> [MilestoneGoalSnapshot]
    public func activeMilestonesForWidget(limit: Int, day: LocalDay) throws -> [WidgetMilestoneSnapshot]
}
```

- [ ] **Step 4: Implement current-milestone logic**

Use this helper everywhere:

```swift
func currentActiveMilestone(finalGoalID: UUID) throws -> MilestoneGoal? {
    try fetchMilestones(finalGoalID: finalGoalID)
        .filter(\.isActive)
        .sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.createdAt < $1.createdAt
            }
            return $0.sortOrder < $1.sortOrder
        }
        .first
}
```

Check-in must enforce:

```swift
guard let current = try currentActiveMilestone(finalGoalID: milestone.finalGoalID),
      current.id == milestoneGoalID else {
    throw GoalRepositoryError.notCurrentMilestone
}
```

- [ ] **Step 5: Implement check-in and auto-completion**

Check-in behavior:

```swift
let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
guard try fetchCompletion(uniqueKey: uniqueKey) == nil else { return }

if milestone.startDayKey == nil {
    milestone.startDayKey = day.rawValue
}
modelContext.insert(DailyCompletion(goalID: milestoneGoalID, dayKey: day.rawValue))

let completedDays = try completedDays(for: milestoneGoalID)
if completedDays >= milestone.targetCompletionDays {
    milestone.completedAt = Date()
}
milestone.updatedAt = Date()
try save()
```

Because `completedDays(for:)` reads from the context, make sure it counts the inserted object. If SwiftData does not include the pending insert before save in this environment, compute `completedDays + 1` before inserting.

- [ ] **Step 6: Implement undo behavior**

Undo behavior:

```swift
let uniqueKey = DailyCompletion.makeUniqueKey(goalID: milestoneGoalID, dayKey: day.rawValue)
guard let completion = try fetchCompletion(uniqueKey: uniqueKey) else { return }
modelContext.delete(completion)

let remainingCount = max(try completedDays(for: milestoneGoalID) - 1, 0)
if remainingCount < milestone.targetCompletionDays {
    milestone.completedAt = nil
}
milestone.updatedAt = Date()
try save()
```

This makes app-only undo consistent with the invariant that a milestone is complete only when `completedDays >= targetCompletionDays`.

- [ ] **Step 7: Implement milestone list snapshots**

Snapshot rules:

```swift
let currentID = try currentActiveMilestone(finalGoalID: finalGoalID)?.id
let completedDays = try completedDays(for: milestone.id)
let remainingDays = max(milestone.targetCompletionDays - completedDays, 0)
let completionRate = Double(completedDays) / Double(milestone.targetCompletionDays)
```

Each `MilestoneGoalSnapshot` should include:

```swift
isCurrent: milestone.id == currentID
recentActivity: try recentActivity(goalID: milestone.id, endingOn: day)
```

- [ ] **Step 8: Implement widget snapshots**

Widget query rules:

```swift
let boundedLimit = max(limit, 0)
guard boundedLimit > 0 else { return [] }
let activeFinalGoals = try fetchFinalGoals()
    .filter(\.isActive)
    .sorted { $0.sortOrder < $1.sortOrder }

return try activeFinalGoals.compactMap { finalGoal in
    guard let milestone = try currentActiveMilestone(finalGoalID: finalGoal.id) else { return nil }
    return WidgetMilestoneSnapshot(
        id: milestone.id,
        finalGoalID: finalGoal.id,
        title: milestone.title,
        parentTitle: finalGoal.title,
        targetCompletionDays: milestone.targetCompletionDays,
        completedDays: try completedDays(for: milestone.id),
        isCompletedToday: try isCompleted(goalID: milestone.id, day: day)
    )
}.prefix(boundedLimit).map { $0 }
```

- [ ] **Step 9: Run milestone tests**

Run:

```bash
swift test --package-path Packages/OneStepCore --filter MilestoneGoalRepositoryTests
```

Expected: PASS.

- [ ] **Step 10: Run all core tests**

Run:

```bash
swift test --package-path Packages/OneStepCore
```

Expected: PASS.

- [ ] **Step 11: Commit**

```bash
git add Packages/OneStepCore/Sources/OneStepCore/Repositories/MilestoneGoalRepository.swift Packages/OneStepCore/Tests/OneStepCoreTests
git commit -m "feat: add milestone goal repository"
```

## Task 4: App Stores

**Files:**
- Delete: `OneStep/App/GoalStore.swift`
- Create: `OneStep/App/FinalGoalStore.swift`
- Create: `OneStep/App/MilestoneGoalStore.swift`
- Modify: `OneStepTests/GoalStoreTests.swift`

- [ ] **Step 1: Replace store tests with hierarchy store tests**

In `OneStepTests/GoalStoreTests.swift`, replace `GoalStoreTests` with:

```swift
@MainActor
final class FinalGoalStoreTests: XCTestCase {
    func testRefreshLoadsFinalGoalsFromRepositoryForRequestedDay() throws
    func testCreateFinalGoalMarksFirstGoalAndRefreshesList() throws
    func testUpdateCompleteArchiveAndMoveRefreshListState() throws
}

@MainActor
final class MilestoneGoalStoreTests: XCTestCase {
    func testRefreshLoadsMilestonesForSelectedFinalGoal() throws
    func testCreateMilestoneRefreshesMilestoneAndFinalGoalStores() throws
    func testCompleteUndoAndArchiveRefreshMilestoneState() throws
}
```

Use one `ModelContext` per fixture:

```swift
let container = try OneStepModelContainerFactory.makeInMemory()
let context = ModelContext(container)
let finalRepository = FinalGoalRepository(modelContext: context)
let milestoneRepository = MilestoneGoalRepository(modelContext: context)
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' -only-testing:OneStepTests/FinalGoalStoreTests
```

Expected: FAIL because the new stores do not exist.

- [ ] **Step 3: Create `FinalGoalStore.swift`**

Public store shape:

```swift
@MainActor
@Observable
final class FinalGoalStore {
    private let repository: FinalGoalRepository

    var finalGoals: [FinalGoalListSnapshot] = []
    var selectedFinalGoalID: UUID?
    var errorMessage: String?
    var didCreateFirstGoal = false

    init(repository: FinalGoalRepository) {
        self.repository = repository
    }

    static func live() throws -> FinalGoalStore {
        FinalGoalStore(repository: try FinalGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }

    var selectedFinalGoal: FinalGoalListSnapshot? {
        guard let selectedFinalGoalID else { return finalGoals.first { $0.archivedAt == nil && $0.completedAt == nil } }
        return finalGoals.first { $0.id == selectedFinalGoalID }
    }
}
```

Methods:

```swift
func refresh(day: LocalDay = .today)
func createFinalGoal(title: String, goalDescription: String?, targetCalendarDays: Int?)
func updateFinalGoal(finalGoalID: UUID, title: String, goalDescription: String?, targetCalendarDays: Int?)
func completeFinalGoal(finalGoalID: UUID)
func archiveFinalGoal(finalGoalID: UUID)
func move(from source: IndexSet, to destination: Int)
func select(finalGoalID: UUID?)
```

Every mutation should call:

```swift
refresh()
WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
```

- [ ] **Step 4: Create `MilestoneGoalStore.swift`**

Store shape:

```swift
@MainActor
@Observable
final class MilestoneGoalStore {
    private let repository: MilestoneGoalRepository

    var milestones: [MilestoneGoalSnapshot] = []
    var errorMessage: String?

    init(repository: MilestoneGoalRepository) {
        self.repository = repository
    }

    static func live() throws -> MilestoneGoalStore {
        MilestoneGoalStore(repository: try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }
}
```

Methods:

```swift
func refresh(finalGoalID: UUID?, day: LocalDay = .today)
func createMilestone(finalGoalID: UUID, title: String, targetCompletionDays: Int)
func updateMilestone(milestoneGoalID: UUID, title: String, targetCompletionDays: Int, finalGoalID: UUID)
func completeToday(milestoneGoalID: UUID, finalGoalID: UUID)
func uncompleteToday(milestoneGoalID: UUID, finalGoalID: UUID)
func archiveMilestone(milestoneGoalID: UUID, finalGoalID: UUID)
```

If `finalGoalID` is nil, `refresh` should set `milestones = []`.

- [ ] **Step 5: Delete old store**

Remove `OneStep/App/GoalStore.swift`.

- [ ] **Step 6: Run app store tests**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' -only-testing:OneStepTests/FinalGoalStoreTests -only-testing:OneStepTests/MilestoneGoalStoreTests
```

Expected: PASS after Xcode project references are updated in Task 5. If this fails here because the new files are not in the project target, continue to Task 5 and rerun.

- [ ] **Step 7: Commit**

```bash
git add OneStep/App OneStepTests/GoalStoreTests.swift
git commit -m "feat: add hierarchy app stores"
```

## Task 5: App Views and Xcode Project References

**Files:**
- Modify: `OneStep/Views/ContentView.swift`
- Modify: `OneStep/Views/GoalListView.swift`
- Create: `OneStep/Views/FinalGoalDetailView.swift`
- Modify: `OneStep/Views/GoalRowView.swift`
- Modify: `OneStep/Views/GoalEditorView.swift`
- Modify: `OneStep/Views/EmptyStateView.swift`
- Modify: `OneStep.xcodeproj/project.pbxproj`

- [ ] **Step 1: Update `ContentView.swift`**

Replace single-store state with:

```swift
@State private var finalGoalStore: FinalGoalStore?
@State private var milestoneGoalStore: MilestoneGoalStore?
@State private var startupError: String?
@State private var isShowingCreateFinalGoal = false
```

Initialize both stores in `.task`:

```swift
let finalStore = try FinalGoalStore.live()
let milestoneStore = try MilestoneGoalStore.live()
finalStore.refresh()
milestoneStore.refresh(finalGoalID: finalStore.selectedFinalGoal?.id)
finalGoalStore = finalStore
milestoneGoalStore = milestoneStore
```

Present `FinalGoalEditorView(mode: .create)` and call:

```swift
finalStore.createFinalGoal(
    title: title,
    goalDescription: description,
    targetCalendarDays: targetCalendarDays
)
```

- [ ] **Step 2: Update `GoalListView.swift`**

Use sidebar rows for final goals:

```swift
FinalGoalRowView(goal: goal)
    .tag(goal.id)
```

The detail pane should render:

```swift
if let selected = finalGoalStore.selectedFinalGoal {
    FinalGoalDetailView(
        finalGoal: selected,
        finalGoalStore: finalGoalStore,
        milestoneGoalStore: milestoneGoalStore
    )
} else {
    EmptyStateView { isShowingCreateFinalGoal = true }
}
```

On selection change, call:

```swift
milestoneGoalStore.refresh(finalGoalID: newSelection)
```

- [ ] **Step 3: Create `FinalGoalDetailView.swift`**

View responsibilities:

```swift
struct FinalGoalDetailView: View {
    let finalGoal: FinalGoalListSnapshot
    @Bindable var finalGoalStore: FinalGoalStore
    @Bindable var milestoneGoalStore: MilestoneGoalStore
    @State private var editingFinalGoal: FinalGoalListSnapshot?
    @State private var editingMilestone: MilestoneGoalSnapshot?
    @State private var isShowingAddMilestone = false
}
```

Required controls:

```swift
Button { editingFinalGoal = finalGoal } label: { Label("Edit", systemImage: "pencil") }
Button { isShowingAddMilestone = true } label: { Label("Add Milestone", systemImage: "plus") }
Button { finalGoalStore.completeFinalGoal(finalGoalID: finalGoal.id) } label: { Label("Complete Final Goal", systemImage: "checkmark.seal") }
    .disabled(finalGoal.totalMilestoneCount == 0 || finalGoal.completedMilestoneCount != finalGoal.totalMilestoneCount)
```

Milestone rows:

```swift
ForEach(milestoneGoalStore.milestones) { milestone in
    MilestoneGoalRowView(
        milestone: milestone,
        onComplete: { milestoneGoalStore.completeToday(milestoneGoalID: milestone.id, finalGoalID: finalGoal.id) },
        onUndo: { milestoneGoalStore.uncompleteToday(milestoneGoalID: milestone.id, finalGoalID: finalGoal.id) },
        onEdit: { editingMilestone = milestone },
        onArchive: { milestoneGoalStore.archiveMilestone(milestoneGoalID: milestone.id, finalGoalID: finalGoal.id) }
    )
}
```

- [ ] **Step 4: Split row views inside `GoalRowView.swift`**

Replace `GoalRowView` with:

```swift
struct FinalGoalRowView: View {
    let goal: FinalGoalListSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.title).lineLimit(1)
            HStack(spacing: 6) {
                Text("\(goal.completedMilestoneCount)/\(goal.totalMilestoneCount)")
                if let remaining = goal.remainingCalendarDays {
                    Text("\(remaining) days")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
```

And:

```swift
struct MilestoneGoalRowView: View {
    let milestone: MilestoneGoalSnapshot
    let onComplete: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
}
```

The milestone row should show a check-in button only when `milestone.isCurrent && milestone.archivedAt == nil && milestone.completedAt == nil`. Completed rows show `checkmark.circle.fill`; archived rows disable edit/check-in/archive actions.

- [ ] **Step 5: Split editor views inside `GoalEditorView.swift`**

Replace `GoalEditorView` with:

```swift
struct FinalGoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, goalDescription: String?, targetCalendarDays: Int?)
    }
    let mode: Mode
    let onSave: (String, String?, Int?) -> Void
}
```

Fields:

```swift
TextField("Pass IELTS", text: $title)
TextField("Reach band 7", text: $goalDescription, axis: .vertical)
Toggle("Calendar limit", isOn: $hasCalendarLimit)
Stepper(value: $targetCalendarDays, in: 1...10_000) {
    Text("\(targetCalendarDays) calendar days")
}
```

Create:

```swift
struct MilestoneGoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, targetCompletionDays: Int)
    }
    let mode: Mode
    let onSave: (String, Int) -> Void
}
```

Fields:

```swift
TextField("Finish vocabulary", text: $title)
Stepper(value: $targetCompletionDays, in: 1...10_000) {
    Text("Target: \(targetCompletionDays) completed days")
}
```

- [ ] **Step 6: Update empty-state text**

Change `EmptyStateView` copy to refer to final goals:

```swift
ContentUnavailableView(
    "Create your first final goal",
    systemImage: "target",
    description: Text("Break a long-term aspiration into milestones, then check in on the current one each day.")
)
```

- [ ] **Step 7: Update Xcode project references**

In `OneStep.xcodeproj/project.pbxproj`:

- Remove `GoalStore.swift` file ref and build file.
- Add `FinalGoalStore.swift` file ref and build file to the `OneStep` target Sources phase.
- Add `MilestoneGoalStore.swift` file ref and build file to the `OneStep` target Sources phase.
- Add `FinalGoalDetailView.swift` file ref and build file to the `OneStep` target Sources phase.

Use the same deterministic ID style already in the project, for example:

```text
A1000000000000000000002C /* FinalGoalStore.swift */
A1000000000000000000002D /* MilestoneGoalStore.swift */
A1000000000000000000002E /* FinalGoalDetailView.swift */
```

- [ ] **Step 8: Run app tests**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add OneStep/Views OneStep/App OneStepTests/GoalStoreTests.swift OneStep.xcodeproj/project.pbxproj
git commit -m "feat: update app for goal hierarchy"
```

## Task 6: Widget Milestone Flow

**Files:**
- Modify: `OneStepWidget/OneStepTimelineProvider.swift`
- Modify: `OneStepWidget/OneStepWidget.swift`
- Modify: `OneStepWidget/CompleteGoalIntent.swift`
- Modify: `OneStepWidget/WidgetGoalRowView.swift`

- [ ] **Step 1: Update timeline entry type**

Change:

```swift
let goals: [WidgetGoalSnapshot]
```

To:

```swift
let milestones: [WidgetMilestoneSnapshot]
```

- [ ] **Step 2: Load active milestones**

In `OneStepTimelineProvider.loadEntry`, replace `GoalRepository` usage with:

```swift
let repository = try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
let milestones = try repository.activeMilestonesForWidget(limit: family.goalLimit, day: .today)
return OneStepWidgetEntry(date: Date(), milestones: milestones)
```

Keep `goalLimit` as the widget-family limit name to minimize churn.

- [ ] **Step 3: Update widget view**

Change empty text to:

```swift
Text("Create a final goal and add a milestone in the app.")
```

Render:

```swift
ForEach(entry.milestones) { milestone in
    WidgetGoalRowView(milestone: milestone, compact: family == .systemSmall)
}
```

- [ ] **Step 4: Update `CompleteGoalIntent`**

Keep the parameter name:

```swift
@Parameter(title: "Goal ID")
var goalID: String
```

Change the initializer comment and perform implementation so `goalID` means `MilestoneGoal.id`:

```swift
init(goalID: UUID) {
    self.goalID = goalID.uuidString
}
```

Use:

```swift
let repository = try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
try repository.completeToday(milestoneGoalID: id, day: .today)
```

Catch:

```swift
} catch GoalRepositoryError.milestoneGoalNotFound {
    OneStepLog.appIntent.error("Stale widget tap ignored because milestone was missing: \(goalID)")
} catch GoalRepositoryError.milestoneGoalNotActive {
    OneStepLog.appIntent.error("Stale widget tap ignored because milestone was archived or completed: \(goalID)")
} catch GoalRepositoryError.notCurrentMilestone {
    OneStepLog.appIntent.error("Stale widget tap ignored because milestone was no longer current: \(goalID)")
}
```

- [ ] **Step 5: Update widget row**

Change stored property:

```swift
let milestone: WidgetMilestoneSnapshot
```

Render:

```swift
Button(intent: CompleteGoalIntent(goalID: milestone.id)) {
    HStack(spacing: 8) {
        Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
        VStack(alignment: .leading, spacing: 2) {
            Text(milestone.title).lineLimit(1)
            if !compact {
                Text(milestone.parentTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
.disabled(milestone.isCompletedToday)
```

- [ ] **Step 6: Build widget target**

Run:

```bash
xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add OneStepWidget
git commit -m "feat: target active milestones from widget"
```

## Task 7: Documentation Updates

**Files:**
- Modify: `docs/engineering/data-schema-and-migration.md`
- Modify: `docs/product/v1-product-spec.md`
- Modify: `docs/qa/release-checklist.md`

- [ ] **Step 1: Update data schema documentation**

Document:

```markdown
## Current Schema

`FinalGoal` represents the long-term aspiration. It stores title, optional description, optional motivational calendar-day target, start day, sidebar sort order, completion timestamp, archive timestamp, and audit timestamps.

`MilestoneGoal` represents one ordered phase inside a final goal. It stores title, required target completion days, parent `finalGoalID`, parent-local sort order, first check-in day, completion timestamp, archive timestamp, and audit timestamps.

`DailyCompletion.goalID` stores `MilestoneGoal.id`. The persisted field name remains `goalID`; the unique key remains `{milestoneGoalID}#{dayKey}`.
```

Add invariants:

```markdown
- Only the current active milestone for a final goal can receive a check-in.
- A milestone auto-completes when its completion count reaches `targetCompletionDays`.
- A final goal completes only by manual user confirmation after every milestone has completed.
- Archiving a final goal archives incomplete milestones under it.
- Deleting a final goal deletes its milestones and their completions.
- There is no migration from the pre-v1 flat `Goal` schema.
```

- [ ] **Step 2: Update product spec**

Replace flat goal behavior with:

```markdown
One Step organizes work into final goals and milestone goals. The sidebar lists final goals. The detail pane lists milestones in fixed creation order. The app and widget only allow daily check-in for the current active milestone in each final goal.
```

Widget behavior:

```markdown
The widget shows the current active milestone from each active final goal. Tapping a widget row records today's completion for that milestone and reloads timelines. Widget undo is not part of v1.
```

- [ ] **Step 3: Update QA checklist**

Add manual checks:

```markdown
- Create a final goal with no calendar limit.
- Create a final goal with a calendar limit and verify sidebar countdown.
- Add two milestones and verify only the first is current.
- Complete the first milestone to its target and verify the second becomes current.
- Confirm the final goal cannot complete before all milestones are complete.
- Complete all milestones and manually complete the final goal.
- Archive a final goal and verify incomplete milestones are archived.
- Verify widget shows only current active milestones, one per active final goal.
- Tap the widget current milestone and verify the app reflects today's completion.
```

- [ ] **Step 4: Run documentation unresolved-marker scan**

Run:

```bash
rg -n "T[O]DO|T[B]D|fill[[:space:]]in" docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
git commit -m "docs: update goal hierarchy docs"
```

## Task 8: Final Verification and Cleanup

**Files:**
- Validate: `Packages/OneStepCore/Sources/OneStepCore`
- Validate: `Packages/OneStepCore/Tests/OneStepCoreTests`
- Validate: `OneStep`
- Validate: `OneStepWidget`
- Validate: `OneStep.xcodeproj/project.pbxproj`
- Validate: `docs/engineering/data-schema-and-migration.md`
- Validate: `docs/product/v1-product-spec.md`
- Validate: `docs/qa/release-checklist.md`

- [ ] **Step 1: Search for obsolete flat-goal symbols**

Run:

```bash
rg -n "\bGoalRepository\b|\bGoalStore\b|\bGoalListSnapshot\b|\bWidgetGoalSnapshot\b|dailyAction|CreateGoalInput|UpdateGoalInput" Packages OneStep OneStepWidget OneStepTests
```

Expected: no output, except if `GoalRepositoryError` appears as the shared error type.

- [ ] **Step 2: Run core tests**

Run:

```bash
swift test --package-path Packages/OneStepCore
```

Expected: PASS.

- [ ] **Step 3: Run app tests**

Run:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 4: Build widget**

Run:

```bash
xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'
```

Expected: PASS.

- [ ] **Step 5: Run unresolved-marker scan**

Run:

```bash
rg -n "T[O]DO|T[B]D|fill[[:space:]]in" Packages OneStep OneStepWidget OneStepTests docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
```

Expected: no unresolved implementation or documentation marker output.

- [ ] **Step 6: Manual app smoke check**

In the running macOS app:

```text
1. Create "Pass IELTS" as a final goal with description "Reach band 7" and 180 calendar days.
2. Add milestones "Finish vocabulary" with target 1 and "Practice listening" with target 1.
3. Verify only "Finish vocabulary" shows the check-in control.
4. Check in "Finish vocabulary" and verify it shows complete.
5. Verify "Practice listening" becomes the current active milestone.
6. Verify "Complete Final Goal" stays disabled until "Practice listening" is complete.
7. Check in "Practice listening" and manually complete the final goal.
8. Verify the completed final goal leaves the active sidebar list.
```

- [ ] **Step 7: Manual widget smoke check**

With the widget installed:

```text
1. Create an active final goal with one active milestone.
2. Verify the widget row shows the milestone title and final-goal title.
3. Tap the widget row.
4. Verify today's completion appears in the app.
5. Verify repeated tapping does not create duplicate completions.
```

- [ ] **Step 8: Final commit**

If verification required fixes:

```bash
git add Packages OneStep OneStepWidget OneStepTests OneStep.xcodeproj docs/engineering/data-schema-and-migration.md docs/product/v1-product-spec.md docs/qa/release-checklist.md
git commit -m "chore: verify goal hierarchy implementation"
```

If no fixes were required, do not create an empty commit.

## Self-Review

### Spec Coverage

- FinalGoal model fields: Task 1.
- MilestoneGoal model fields: Task 1.
- DailyCompletion field semantics: Task 1.
- Strict milestone advancement: Task 3.
- Current active milestone check-in only: Task 3.
- Auto-complete milestone at target count: Task 3.
- One completion per milestone per day: Task 3.
- App undo only: Task 3 and Task 5.
- Motivational calendar-day countdown: Task 2 and Task 5.
- FinalGoal archive cascades to incomplete milestones: Task 2.
- Milestone archive advances current milestone through computed current selection: Task 3.
- Manual final-goal completion after all milestones: Task 2 and Task 5.
- Delete final goal cascade: Task 2.
- Delete milestone completions: Task 3.
- No milestone reorder after creation: Task 5 has no reorder UI for milestones.
- App NavigationSplitView hierarchy: Task 5.
- Creation flow for final goals and milestones: Task 5.
- Widget active milestones across active final goals: Task 6.
- No data migration: Scope Check and Task 7.
- Documentation updates: Task 7.

### Placeholder Scan

The plan intentionally contains expected command outputs and concrete method names. It does not use unresolved implementation markers.

### Type Consistency

The plan uses these replacement names consistently:

- `FinalGoal`, `MilestoneGoal`, `DailyCompletion`
- `FinalGoalRepository`, `MilestoneGoalRepository`
- `CreateFinalGoalInput`, `UpdateFinalGoalInput`
- `CreateMilestoneGoalInput`, `UpdateMilestoneGoalInput`
- `FinalGoalListSnapshot`, `MilestoneGoalSnapshot`, `WidgetMilestoneSnapshot`
- `FinalGoalStore`, `MilestoneGoalStore`
- `FinalGoalRowView`, `MilestoneGoalRowView`
- `FinalGoalEditorView`, `MilestoneGoalEditorView`
