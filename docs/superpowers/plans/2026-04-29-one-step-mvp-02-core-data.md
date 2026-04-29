# One Step MVP 02 Core Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the `OneStepCore` domain model, SwiftData persistence, repository API, and unit tests for goal creation, completion, archiving, ordering, and Widget snapshots.

**Architecture:** Keep SwiftData model classes inside `OneStepCore` and expose plain snapshot structs to the app and Widget. `GoalRepository` is the only write surface. Date semantics go through `LocalDay`, and duplicate same-day completions are idempotent no-ops.

**Tech Stack:** Swift Package Manager, SwiftData, XCTest, Foundation.

---

## Agent Boundary

Execute only core package work. Do not modify app UI or Widget UI except if Xcode package linkage requires a compile fix.

## Files

- Create: `Packages/OneStepCore/Sources/OneStepCore/Dates/LocalDay.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`
- Create tests under `Packages/OneStepCore/Tests/OneStepCoreTests/`
- Delete: `Packages/OneStepCore/Sources/OneStepCore/OneStepCore.swift`
- Delete: `Packages/OneStepCore/Tests/OneStepCoreTests/OneStepCoreSmokeTests.swift`

## Task 1: LocalDay

- [ ] **Step 1: Write failing tests**

Write `Packages/OneStepCore/Tests/OneStepCoreTests/LocalDayTests.swift`:

```swift
import XCTest
@testable import OneStepCore

final class LocalDayTests: XCTestCase {
    func testLocalDayUsesCalendarYearMonthDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let date = ISO8601DateFormatter().date(from: "2026-04-29T15:59:59Z")!
        XCTAssertEqual(LocalDay(date: date, calendar: calendar).rawValue, "2026-04-29")
    }

    func testSameInstantCanProduceDifferentLocalDays() {
        let instant = ISO8601DateFormatter().date(from: "2026-04-29T00:30:00Z")!
        var shanghai = Calendar(identifier: .gregorian)
        shanghai.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(secondsFromGMT: -7 * 3600)!
        XCTAssertEqual(LocalDay(date: instant, calendar: shanghai).rawValue, "2026-04-29")
        XCTAssertEqual(LocalDay(date: instant, calendar: losAngeles).rawValue, "2026-04-28")
    }

    func testRawValueInitializerAcceptsValidKey() throws {
        let day = try XCTUnwrap(LocalDay(rawValue: "2026-04-29"))
        XCTAssertEqual(day.rawValue, "2026-04-29")
    }

    func testRawValueInitializerRejectsInvalidKey() {
        XCTAssertNil(LocalDay(rawValue: "2026-4-9"))
        XCTAssertNil(LocalDay(rawValue: "not-a-day"))
    }
}
```

- [ ] **Step 2: Run failing test**

```bash
swift test --package-path Packages/OneStepCore --filter LocalDayTests
```

Expected: fails because `LocalDay` does not exist.

- [ ] **Step 3: Implement LocalDay**

Write `Packages/OneStepCore/Sources/OneStepCore/Dates/LocalDay.swift`:

```swift
import Foundation

public struct LocalDay: Hashable, Codable, RawRepresentable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard LocalDay.isValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    public init(date: Date = Date(), calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.rawValue = String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    public static var today: LocalDay {
        LocalDay()
    }

    private static func isValid(_ value: String) -> Bool {
        guard value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return false
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value) != nil
    }
}
```

- [ ] **Step 4: Run passing test**

```bash
swift test --package-path Packages/OneStepCore --filter LocalDayTests
```

Expected: all `LocalDayTests` pass.

## Task 2: Models, Snapshots, and Errors

- [ ] **Step 1: Write SwiftData models**

Write `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`:

```swift
import Foundation
import SwiftData

@Model
public final class Goal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var dailyAction: String
    public var targetCompletionDays: Int
    public var startDayKey: String
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?

    public init(id: UUID = UUID(), title: String, dailyAction: String, targetCompletionDays: Int, startDayKey: String, sortOrder: Int, createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.startDayKey = startDayKey
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }

    public var isActive: Bool { archivedAt == nil }
}
```

Write `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`:

```swift
import Foundation
import SwiftData

@Model
public final class DailyCompletion {
    @Attribute(.unique) public var uniqueKey: String
    public var id: UUID
    public var goalID: UUID
    public var dayKey: String
    public var completedAt: Date

    public init(id: UUID = UUID(), goalID: UUID, dayKey: String, completedAt: Date = Date()) {
        self.id = id
        self.goalID = goalID
        self.dayKey = dayKey
        self.completedAt = completedAt
        self.uniqueKey = DailyCompletion.makeUniqueKey(goalID: goalID, dayKey: dayKey)
    }

    public static func makeUniqueKey(goalID: UUID, dayKey: String) -> String {
        "\(goalID.uuidString)#\(dayKey)"
    }
}
```

- [ ] **Step 2: Write snapshots and errors**

Write `Packages/OneStepCore/Sources/OneStepCore/Snapshots/GoalSnapshots.swift`:

```swift
import Foundation

public struct CreateGoalInput: Equatable, Sendable {
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let startDay: LocalDay

    public init(title: String, dailyAction: String, targetCompletionDays: Int, startDay: LocalDay) {
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.startDay = startDay
    }
}

public struct UpdateGoalInput: Equatable, Sendable {
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int

    public init(title: String, dailyAction: String, targetCompletionDays: Int) {
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
    }
}

public struct GoalListSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let remainingDays: Int
    public let completionRate: Double
    public let isCompletedToday: Bool
    public let sortOrder: Int
    public let archivedAt: Date?
    public let recentActivity: [RecentActivityDay]

    public init(id: UUID, title: String, dailyAction: String, targetCompletionDays: Int, completedDays: Int, remainingDays: Int, completionRate: Double, isCompletedToday: Bool, sortOrder: Int, archivedAt: Date?, recentActivity: [RecentActivityDay]) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
        self.targetCompletionDays = targetCompletionDays
        self.completedDays = completedDays
        self.remainingDays = remainingDays
        self.completionRate = completionRate
        self.isCompletedToday = isCompletedToday
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.recentActivity = recentActivity
    }
}

public struct WidgetGoalSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let dailyAction: String
    public let targetCompletionDays: Int
    public let completedDays: Int
    public let isCompletedToday: Bool

    public init(id: UUID, title: String, dailyAction: String, targetCompletionDays: Int, completedDays: Int, isCompletedToday: Bool) {
        self.id = id
        self.title = title
        self.dailyAction = dailyAction
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

Write `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepositoryError.swift`:

```swift
import Foundation

public enum GoalRepositoryError: Error, Equatable, LocalizedError {
    case goalNotFound
    case goalNotActive
    case invalidTitle
    case invalidDailyAction
    case invalidTargetCompletionDays
    case targetBelowCompletedCount
    case storeUnavailable
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .goalNotFound:
            return "Goal not found."
        case .goalNotActive:
            return "Goal is archived."
        case .invalidTitle:
            return "Goal title is required."
        case .invalidDailyAction:
            return "Daily action is required."
        case .invalidTargetCompletionDays:
            return "Target completion days must be greater than zero."
        case .targetBelowCompletedCount:
            return "Target completion days cannot be below completed days."
        case .storeUnavailable:
            return "Shared store is unavailable."
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
```

- [ ] **Step 3: Compile package**

```bash
swift test --package-path Packages/OneStepCore
```

Expected: package compiles and `LocalDayTests` pass.

## Task 3: Model Container and Repository

- [ ] **Step 1: Add repository tests**

Create tests for:

```swift
GoalRepository.createGoal accepts valid data and trims strings
GoalRepository.createGoal rejects empty title
GoalRepository.createGoal rejects empty dailyAction
GoalRepository.createGoal rejects targetCompletionDays <= 0
GoalRepository.completeToday inserts one completion
GoalRepository.completeToday is idempotent for the same goal/day
GoalRepository.completeToday throws goalNotFound for missing ID
GoalRepository.completeToday throws goalNotActive for archived goal
GoalRepository.uncompleteToday removes only today's record
GoalRepository.updateGoal rejects target below completed count
GoalRepository.moveActiveGoal changes active Widget order
GoalRepository.activeGoalsForWidget excludes archived goals and respects limit
```

Use in-memory containers in every test:

```swift
let container = try OneStepModelContainerFactory.makeInMemory()
let repository = GoalRepository(modelContext: ModelContext(container))
```

- [ ] **Step 2: Run failing repository tests**

```bash
swift test --package-path Packages/OneStepCore --filter GoalRepository
```

Expected: tests fail because the factory and repository do not exist.

- [ ] **Step 3: Implement container factory**

Write `Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift`:

```swift
import Foundation
import SwiftData

public enum OneStepModelContainerFactory {
    public static let storeFileName = "OneStep.sqlite"

    public static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([Goal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStepTests", schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeShared(appGroupIdentifier: String) throws -> ModelContainer {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw GoalRepositoryError.storeUnavailable
        }
        let url = storeURL(appGroupContainerURL: appGroupURL)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema([Goal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStep", schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func storeURL(appGroupContainerURL: URL) -> URL {
        appGroupContainerURL.appending(path: "OneStep", directoryHint: .isDirectory).appending(path: storeFileName)
    }
}
```

- [ ] **Step 4: Implement repository**

Write `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift` with the exact public surface from the master plan. Implementation requirements:

```swift
@MainActor
public struct GoalRepository {
    private let modelContext: ModelContext
    public init(modelContext: ModelContext)
    public static func shared(appGroupIdentifier: String) throws -> GoalRepository
}
```

Behavior requirements:

```text
createGoal trims title/action, validates target > 0, assigns next sortOrder.
goalsForList returns all goals sorted by sortOrder then createdAt.
activeGoalsForWidget returns active goals only, sorted by sortOrder, limited by max(limit, 0).
completeToday verifies goal exists and is active, then inserts DailyCompletion unless uniqueKey already exists.
uncompleteToday deletes the completion for that goal/day only.
archiveGoal sets archivedAt and updatedAt.
updateGoal validates title/action/target and rejects target below completed count.
moveActiveGoal reorders only active goals and rewrites contiguous sortOrder values.
recentActivity returns 30 days ending on the requested LocalDay.
```

- [ ] **Step 5: Remove smoke placeholder**

Delete:

```text
Packages/OneStepCore/Sources/OneStepCore/OneStepCore.swift
Packages/OneStepCore/Tests/OneStepCoreTests/OneStepCoreSmokeTests.swift
```

- [ ] **Step 6: Run all core tests**

```bash
swift test --package-path Packages/OneStepCore
```

Expected: all `OneStepCoreTests` pass.

- [ ] **Step 7: Commit**

```bash
git add Packages/OneStepCore
git commit -m "feat: implement one step core data"
```

## Self-Review

- `LocalDay` tests cover local calendar behavior.
- Repository tests cover duplicate completion, stale missing goal, archived goal, ordering, and Widget limits.
- App and Widget UI were not built in this plan.
