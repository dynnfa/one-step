# One Step MVP 04 Main App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the spike UI with the MVP main app workflow for creating, editing, archiving, ordering, completing, undoing, and reviewing goals.

**Architecture:** The app uses a thin `GoalStore` adapter over `GoalRepository`. SwiftUI views render `GoalListSnapshot` values and do not access SwiftData models directly. Widget reloads are requested after app writes so the desktop state catches up.

**Tech Stack:** SwiftUI, Observation, WidgetKit reload calls, `OneStepCore`.

---

## Agent Boundary

Execute only the main app UI. Do not redesign the Widget in this plan.

## Files

- Create: `OneStep/App/GoalStore.swift`
- Modify: `OneStep/Views/ContentView.swift`
- Create: `OneStep/Views/EmptyStateView.swift`
- Create: `OneStep/Views/GoalEditorView.swift`
- Create: `OneStep/Views/GoalListView.swift`
- Create: `OneStep/Views/GoalRowView.swift`
- Create: `OneStep/Views/RecentActivityView.swift`

## Task 1: Store Adapter

- [ ] **Step 1: Write GoalStore**

Write `OneStep/App/GoalStore.swift`:

```swift
import Foundation
import OneStepCore
import Observation
import WidgetKit

@MainActor
@Observable
final class GoalStore {
    private let repository: GoalRepository

    var goals: [GoalListSnapshot] = []
    var errorMessage: String?
    var didCreateFirstGoal = false

    init(repository: GoalRepository) {
        self.repository = repository
    }

    static func live() throws -> GoalStore {
        GoalStore(repository: try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }

    func refresh(day: LocalDay = .today) {
        do {
            goals = try repository.goalsForList(day: day)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            OneStepLog.repository.error("App refresh failed: \(error.localizedDescription)")
        }
    }

    func createGoal(title: String, dailyAction: String, targetCompletionDays: Int) {
        do {
            let wasEmpty = goals.isEmpty
            try repository.createGoal(CreateGoalInput(title: title, dailyAction: dailyAction, targetCompletionDays: targetCompletionDays, startDay: .today))
            didCreateFirstGoal = wasEmpty
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGoal(goalID: UUID, title: String, dailyAction: String, targetCompletionDays: Int) {
        do {
            try repository.updateGoal(goalID: goalID, input: UpdateGoalInput(title: title, dailyAction: dailyAction, targetCompletionDays: targetCompletionDays))
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeToday(goalID: UUID) {
        do {
            try repository.completeToday(goalID: goalID, day: .today)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uncompleteToday(goalID: UUID) {
        do {
            try repository.uncompleteToday(goalID: goalID, day: .today)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveGoal(goalID: UUID) {
        do {
            try repository.archiveGoal(goalID: goalID, archivedAt: Date())
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        let activeGoals = goals.filter { $0.archivedAt == nil }
        guard sourceIndex < activeGoals.count else { return }

        do {
            try repository.moveActiveGoal(goalID: activeGoals[sourceIndex].id, toIndex: destination)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAndReloadWidget() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
    }
}
```

## Task 2: First-Run and Editor Views

- [ ] **Step 1: Write EmptyStateView**

Write `OneStep/Views/EmptyStateView.swift`:

```swift
import SwiftUI

struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.tint)
            Text("Start with one long-term goal.")
                .font(.title2.bold())
            Text("Pick a daily action you can honestly confirm from the desktop.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Create Goal", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

- [ ] **Step 2: Write GoalEditorView**

Write `OneStep/Views/GoalEditorView.swift`:

```swift
import SwiftUI

struct GoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, dailyAction: String, targetCompletionDays: Int)

        var title: String {
            switch self {
            case .create: return "Create Goal"
            case .edit: return "Edit Goal"
            }
        }
    }

    let mode: Mode
    let onSave: (String, String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var dailyAction: String
    @State private var targetCompletionDays: Int

    init(mode: Mode, onSave: @escaping (String, String, Int) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _dailyAction = State(initialValue: "")
            _targetCompletionDays = State(initialValue: 200)
        case let .edit(title, dailyAction, targetCompletionDays):
            _title = State(initialValue: title)
            _dailyAction = State(initialValue: dailyAction)
            _targetCompletionDays = State(initialValue: targetCompletionDays)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Vocabulary", text: $title).textFieldStyle(.roundedBorder)
            TextField("Study 30 minutes", text: $dailyAction).textFieldStyle(.roundedBorder)
            Stepper(value: $targetCompletionDays, in: 1...10_000) {
                Text("Target: \(targetCompletionDays) completed days")
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(title, dailyAction, targetCompletionDays) }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dailyAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
```

## Task 3: Goal List Views

- [ ] **Step 1: Write RecentActivityView**

Write `OneStep/Views/RecentActivityView.swift`:

```swift
import OneStepCore
import SwiftUI

struct RecentActivityView: View {
    let activity: [RecentActivityDay]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(activity.suffix(30)) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(day.isCompleted ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 8, height: 18)
                    .accessibilityLabel("\(day.day.rawValue) \(day.isCompleted ? "completed" : "missed")")
            }
        }
    }
}
```

- [ ] **Step 2: Write GoalRowView**

Write `OneStep/Views/GoalRowView.swift`:

```swift
import OneStepCore
import SwiftUI

struct GoalRowView: View {
    let goal: GoalListSnapshot
    let onComplete: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: goal.isCompletedToday ? onUndo : onComplete) {
                Image(systemName: goal.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title).font(.headline)
                Text(goal.dailyAction).foregroundStyle(.secondary)
                RecentActivityView(activity: goal.recentActivity)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(goal.completedDays)/\(goal.targetCompletionDays)").font(.headline.monospacedDigit())
                Text("\(goal.remainingDays) remaining").font(.caption).foregroundStyle(.secondary)
                Text(goal.completionRate, format: .percent.precision(.fractionLength(0))).font(.caption).foregroundStyle(.secondary)
            }

            Menu {
                Button("Edit", action: onEdit)
                Button("Archive", role: .destructive, action: onArchive).disabled(goal.archivedAt != nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .frame(width: 32)
        }
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 3: Write GoalListView**

Write `OneStep/Views/GoalListView.swift`:

```swift
import OneStepCore
import SwiftUI

struct GoalListView: View {
    @Bindable var store: GoalStore
    @Binding var isShowingCreateGoal: Bool
    @State private var editingGoal: GoalListSnapshot?

    private var activeGoals: [GoalListSnapshot] { store.goals.filter { $0.archivedAt == nil } }
    private var archivedGoals: [GoalListSnapshot] { store.goals.filter { $0.archivedAt != nil } }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Active") {
                    ForEach(activeGoals) { goal in
                        Text(goal.title)
                    }
                    .onMove(perform: store.move)
                }
                if !archivedGoals.isEmpty {
                    Section("Archived") {
                        ForEach(archivedGoals) { goal in
                            Text(goal.title).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isShowingCreateGoal = true } label: {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let error = store.errorMessage {
                    Text(error).foregroundStyle(.red).padding(.horizontal).padding(.bottom, 8)
                }
                if store.goals.isEmpty {
                    EmptyStateView { isShowingCreateGoal = true }
                } else {
                    List {
                        Section("Active Goals") {
                            ForEach(activeGoals) { goal in
                                GoalRowView(
                                    goal: goal,
                                    onComplete: { store.completeToday(goalID: goal.id) },
                                    onUndo: { store.uncompleteToday(goalID: goal.id) },
                                    onEdit: { editingGoal = goal },
                                    onArchive: { store.archiveGoal(goalID: goal.id) }
                                )
                            }
                            .onMove(perform: store.move)
                        }
                        if !archivedGoals.isEmpty {
                            Section("Archived Goals") {
                                ForEach(archivedGoals) { goal in
                                    GoalRowView(goal: goal, onComplete: {}, onUndo: {}, onEdit: { editingGoal = goal }, onArchive: {})
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .onAppear { store.refresh() }
        .sheet(item: $editingGoal) { goal in
            GoalEditorView(mode: .edit(title: goal.title, dailyAction: goal.dailyAction, targetCompletionDays: goal.targetCompletionDays)) { title, action, target in
                store.updateGoal(goalID: goal.id, title: title, dailyAction: action, targetCompletionDays: target)
                editingGoal = nil
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("One Step").font(.largeTitle.bold())
                Text("Confirm today's progress without turning it into a task manager.").foregroundStyle(.secondary)
            }
            Spacer()
            Button { isShowingCreateGoal = true } label: {
                Label("Add Goal", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Task 4: ContentView Integration

- [ ] **Step 1: Write ContentView**

Write `OneStep/Views/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State private var store: GoalStore?
    @State private var startupError: String?
    @State private var isShowingCreateGoal = false

    var body: some View {
        Group {
            if let store {
                GoalListView(store: store, isShowingCreateGoal: $isShowingCreateGoal)
            } else {
                ContentUnavailableView("One Step could not open the shared store", systemImage: "exclamationmark.triangle", description: Text(startupError ?? "Unknown error"))
            }
        }
        .task {
            guard store == nil else { return }
            do {
                let liveStore = try GoalStore.live()
                liveStore.refresh()
                store = liveStore
            } catch {
                startupError = error.localizedDescription
            }
        }
        .sheet(isPresented: $isShowingCreateGoal) {
            if let store {
                GoalEditorView(mode: .create) { title, action, target in
                    store.createGoal(title: title, dailyAction: action, targetCompletionDays: target)
                    isShowingCreateGoal = false
                }
            }
        }
        .alert("Add the One Step Widget", isPresented: Binding(get: { store?.didCreateFirstGoal == true }, set: { _ in store?.didCreateFirstGoal = false })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your first goal is ready. Add the One Step Widget to complete it from the desktop.")
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}
```

- [ ] **Step 2: Build app**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

Expected: build succeeds.

- [ ] **Step 3: Manual app verification**

Verify:

```text
Empty state appears when no goals exist.
Create "Vocabulary / Study 30 minutes / 200 days".
Goal appears in active list.
Complete today in app.
Undo today's completion in app.
Edit title and daily action.
Try setting target below completed count and confirm an error is shown.
Archive removes the goal from active section and shows it in archived section.
Reorder active goals and confirm app order changes.
```

- [ ] **Step 4: Commit**

```bash
git add OneStep
git commit -m "feat: build main app goal workflow"
```

## Self-Review

- App views use snapshots, not SwiftData models.
- Undo exists only in app UI.
- App writes request Widget reload.
- Widget UI remains temporary until the Widget plan.
