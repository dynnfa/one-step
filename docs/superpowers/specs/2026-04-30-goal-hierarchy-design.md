# Goal Hierarchy Design: Final Goals & Milestone Goals

Date: 2026-04-30

## Problem

The current goal system is flat — each Goal directly contains `title`, `dailyAction`, and `targetCompletionDays`, and check-ins are against the Goal itself. There is no hierarchy. This makes it impossible to represent a long-term aspiration (e.g., "pass the IELTS exam") that decomposes into sequential phases ("finish vocabulary", "practice listening", "complete mock exams").

## Decision

Split the single `Goal` model into two models: **FinalGoal** (the long-term aspiration) and **MilestoneGoal** (a sequential phase within that aspiration). Daily check-ins happen against MilestoneGoals. MilestoneGoals advance in strict order — only the current active milestone can receive check-ins. When all milestones are complete, the user manually confirms the FinalGoal as done.

Old Goal data is not migrated. The project is pre-v1.0 and the schema starts fresh.

## Data Model

### FinalGoal

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `UUID` | `@Attribute(.unique)` | Stable, never reused |
| `title` | `String` | Non-empty after trim | User-editable |
| `goalDescription` | `String?` | Optional | Longer description of the aspiration |
| `targetCalendarDays` | `Int?` | Optional, > 0 if set | Motivational deadline in calendar days from creation |
| `startDayKey` | `String` | YYYY-MM-DD | Set on creation |
| `sortOrder` | `Int` | | Manual ordering in the sidebar |
| `completedAt` | `Date?` | `nil` when incomplete | Set manually when user confirms completion |
| `archivedAt` | `Date?` | `nil` when active | Set when archived |
| `createdAt` | `Date` | | Set once |
| `updatedAt` | `Date` | | Updated on every mutation |

Computed: `isActive` = `archivedAt == nil && completedAt == nil`

### MilestoneGoal

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `UUID` | `@Attribute(.unique)` | Stable, never reused |
| `title` | `String` | Non-empty after trim | User-editable |
| `targetCompletionDays` | `Int` | > 0 | Number of check-in days needed |
| `finalGoalID` | `UUID` | Foreign key to `FinalGoal.id` | Determines parent |
| `sortOrder` | `Int` | | Order within the parent FinalGoal |
| `startDayKey` | `String?` | YYYY-MM-DD | Set on first check-in, locked after that |
| `completedAt` | `Date?` | `nil` when incomplete | Auto-set when `completedDays >= targetCompletionDays` |
| `archivedAt` | `Date?` | `nil` when active | Set when archived |
| `createdAt` | `Date` | | Set once |
| `updatedAt` | `Date` | | Updated on every mutation |

Computed: `isActive` = `archivedAt == nil && completedAt == nil`

### DailyCompletion (unchanged)

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Row identifier |
| `goalID` | `UUID` | Now points to `MilestoneGoal.id` |
| `dayKey` | `String` | YYYY-MM-DD |
| `completedAt` | `Date` | Timestamp |
| `uniqueKey` | `String` | `@Attribute(.unique)`, `"{milestoneGoalID}#{dayKey}"` |

## Business Rules

### Milestone Advancement

- Each FinalGoal has an ordered set of MilestoneGoals (by `sortOrder`).
- The **current active milestone** is the one with the smallest `sortOrder` that is `isActive`.
- Only the current active milestone can receive check-ins.
- When `completedDays >= targetCompletionDays` for a milestone, `completedAt` is auto-set and the next milestone becomes active.
- All milestones must be completed before the FinalGoal can be manually confirmed as complete.

### Check-in Rules

- One check-in per MilestoneGoal per day (enforced by `DailyCompletion.uniqueKey`).
- Archived milestones cannot receive check-ins.
- Undo (app only): delete today's `DailyCompletion` for a milestone.

### Calendar Day Limit

- `targetCalendarDays` on FinalGoal is optional and motivational only.
- If set, the UI shows "X days remaining" as a reference. It does not block or warn when exceeded.

### Archival

- Archiving a FinalGoal archives all its incomplete MilestoneGoals.
- Archiving the current active milestone causes the next incomplete milestone to become active.

### Completion

- FinalGoal completion is manual: the user presses a "Complete" button.
- Prerequisite: all MilestoneGoals under that FinalGoal must have `completedAt != nil`.
- Setting `completedAt` on the FinalGoal removes it from the active list.

### Deletion

- Deleting a FinalGoal cascade-deletes all its MilestoneGoals and their DailyCompletions.
- Deleting a MilestoneGoal deletes its DailyCompletions. If the deleted milestone was the current active one, the next incomplete milestone becomes active.

### Milestone Ordering

- MilestoneGoals are ordered by `sortOrder` and advance strictly in that order.
- Reordering milestones is not supported after creation to avoid confusion with sequential progression.

## UI Design

### App (NavigationSplitView)

**Sidebar:** FinalGoal list
- Each row shows: title, milestone progress (e.g., "2/5"), optional day countdown
- Actions: create, delete, archive, reorder

**Detail pane (FinalGoal selected):**
- FinalGoal title + description (editable)
- MilestoneGoal list, ordered by `sortOrder`
  - Each row shows: title, check-in progress (e.g., "12/30 days"), 30-day activity bar
  - Current active milestone is highlighted; check-in button visible
  - Completed milestones show a checkmark
- "Add Milestone" button at the bottom of the list
- "Complete Final Goal" button appears when all milestones are done

### Creation Flow

1. **Create FinalGoal:** title (required), description (optional), calendar day limit (optional).
2. **Add MilestoneGoal** (within FinalGoal detail): title (required), target days (required). `sortOrder` auto-assigned by appending.

### Widget

- Shows all current active milestones across all active FinalGoals (one per FinalGoal).
- Each row can optionally show the parent FinalGoal title in smaller text for context.
- Tap-to-complete targets the MilestoneGoal (same `CompleteGoalIntent` pattern).
- After check-in, widget reloads timelines.

## Architecture Changes

### OneStepCore Package

**Models:**
- Delete `Goal.swift`
- Add `FinalGoal.swift`
- Add `MilestoneGoal.swift`
- Modify `DailyCompletion.swift` (field semantics change; field names stay the same)

**Repositories:**
- Delete `GoalRepository.swift`
- Add `FinalGoalRepository.swift` — CRUD, manual completion, archival
- Add `MilestoneGoalRepository.swift` — CRUD, check-in, undo, archival, milestone advancement logic
- Modify `GoalRepositoryError.swift` — expand error cases

**Snapshots:**
- Modify `GoalSnapshots.swift` — add `FinalGoalListSnapshot`, `MilestoneGoalSnapshot`, `WidgetMilestoneSnapshot`, etc.
- Remove old `GoalListSnapshot`, `WidgetGoalSnapshot`

**Persistence:**
- Modify `OneStepModelContainerFactory.swift` — register `FinalGoal` and `MilestoneGoal`, remove `Goal`

**Tests:**
- Delete `GoalRepositoryTests.swift`, `GoalRepositoryCompletionTests.swift`
- Add `FinalGoalRepositoryTests.swift`
- Add `MilestoneGoalRepositoryTests.swift`

### App Layer

**View models:**
- Delete `GoalStore.swift`
- Add `FinalGoalStore.swift` — manages FinalGoal list, selection, CRUD
- Add `MilestoneGoalStore.swift` — manages MilestoneGoals for selected FinalGoal, check-in, undo

**Views:**
- Modify `ContentView.swift` — adapt to new two-level navigation
- Modify `GoalListView.swift` — sidebar shows FinalGoals
- Add `FinalGoalDetailView.swift` — detail pane with milestone list
- Modify `GoalRowView.swift` — split into FinalGoal row + MilestoneGoal row
- Modify `GoalEditorView.swift` — split into FinalGoal editor + MilestoneGoal editor
- Keep `EmptyStateView.swift` — minor text updates
- Keep `RecentActivityView.swift` — unchanged, shows milestone activity

### Widget Layer

- Modify `OneStepWidget.swift` — read current active milestones
- Modify `OneStepTimelineProvider.swift` — query from new models
- Modify `CompleteGoalIntent.swift` — target MilestoneGoal
- Modify `WidgetGoalRowView.swift` — optional parent FinalGoal title

## Data Migration

None. The project is pre-v1.0. The old `Goal` model and its data are removed. The SwiftData schema starts fresh with `FinalGoal` + `MilestoneGoal`. Users create new data from scratch.
