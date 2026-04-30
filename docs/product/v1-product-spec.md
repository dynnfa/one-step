# V1 Product Spec

This document is the current source of truth for One Step v1 product behavior. For the goal hierarchy design, see `docs/superpowers/specs/2026-04-30-goal-hierarchy-design.md`.

## Product Promise

One Step is a Widget-first local tool for confirming daily progress on long-term goals. The user creates a long-term aspiration, breaks it into sequential milestones, and confirms each day's effort through the desktop Widget. The primary workflow happens on the desktop, not inside an app.

The product does not shame missed days, preserve fake streaks, or try to replace a task manager.

## Goal Hierarchy

One Step uses a two-level hierarchy: **FinalGoal** (long-term aspiration) and **MilestoneGoal** (sequential phase).

### FinalGoal

Represents a long-term aspiration such as "Pass IELTS" or "Ship my app."

Fields:

| Field | Type | Rules |
|-------|------|-------|
| Title | String | Non-empty after trim. |
| Description | String? | Optional longer context. |
| Target calendar days | Int? | Optional deadline from creation date. `nil` means no deadline. |
| Start day | String (YYYY-MM-DD) | Set on creation. |
| Sort order | Int | Manual ordering for display. |
| Completed at | Date? | Set when all milestones are done. |
| Archived at | Date? | `nil` when active. |

### MilestoneGoal

Represents a sequential phase within a FinalGoal, such as "Finish vocabulary" or "Practice listening."

Fields:

| Field | Type | Rules |
|-------|------|-------|
| Title | String | Non-empty after trim. |
| Target completion days | Int | Must be > 0. Represents intended completed days, not calendar duration. |
| Final goal ID | UUID | Parent FinalGoal. |
| Sort order | Int | Determines sequence within the FinalGoal. |
| Start day | String? (YYYY-MM-DD) | Set on first check-in. `nil` until then. |
| Completed at | Date? | Auto-set when `completedDays >= targetCompletionDays`. |
| Archived at | Date? | `nil` when active. |

### Current Active Milestone

At any time, a FinalGoal has at most one **current active milestone**: the first `MilestoneGoal` where `isActive` is true, ordered by `sortOrder`. Only the current active milestone can receive check-ins. When it completes (or is archived), the next active milestone in sort order becomes current.

## FinalGoal Lifecycle

1. **Create.** User enters title, optional description, and optional calendar-day limit. The FinalGoal appears in the sidebar and is available to the Widget through its milestones.
2. **Edit.** User can change title, description, and calendar-day limit.
3. **Complete.** Available only when all milestones are done. Marks the FinalGoal as completed.
4. **Archive.** Cascades to all incomplete milestones. Archived FinalGoals leave the Widget and move to the app's archived section.
5. **Reorder.** User drags FinalGoals into a preferred order. The Widget follows this order.
6. **Delete.** Removes the FinalGoal, all its milestones, and all completions.

## MilestoneGoal Lifecycle

1. **Create.** User enters title and target completion days within a FinalGoal. The milestone is appended at the end of the sort order.
2. **Edit.** User can change title and target completion days. Target days cannot drop below completed count.
3. **Check in (complete today).** Mark daily effort on the current active milestone. Available from the app and the Widget. Sets `startDayKey` on first check-in.
4. **Undo today.** Remove today's completion from the main app. If the milestone was auto-completed, undoing reopens it.
5. **Auto-complete.** When `completedDays >= targetCompletionDays`, the milestone's `completedAt` is set and the next active milestone becomes current.
6. **Archive.** If the current active milestone is archived, the next one becomes current.
7. **Delete.** Removes the milestone and its completions.

## Widget Behavior

The Widget is the primary daily interface. It shows the **current active milestone** for each active FinalGoal, in the user's manual sort order.

| Widget family | Milestones shown |
|---------------|-----------------|
| Small | 1 |
| Medium | 3 |
| Large | 5 |

Each visible milestone displays:

- Milestone title
- Parent FinalGoal title
- Today's completion state
- Completed days / target days

Interaction rules:

- Clicking an incomplete milestone in the Widget completes it for today without opening the app.
- Clicking an already-completed milestone does nothing (idempotent).
- Undo is not available from the Widget in v1.
- Widget timeline refreshes after each completion. Refresh timing is controlled by the system and is not instantaneous.

Empty state: when no active milestones exist, the Widget shows "Create a goal in the app."

## Missed-Day Semantics

- A missed day has no completion record. It is not backfilled, not repairable, and not highlighted.
- Progress counts completed days toward the target, not elapsed calendar days.
- The product does not display streaks, chains, or break counts. The emotional stance is: "I am still on the path," not "I failed."

## Edge Cases

- **Empty states.** First launch invites the user to create a FinalGoal. After the first FinalGoal is saved, the app briefly points toward adding the Widget.
- **Error states.** Repository errors surface as user-visible messages in the app. Widget errors are logged and result in empty data display rather than a crash.
- **Long text.** Titles and descriptions may be long. The app list and Widget rows truncate gracefully without breaking layout.
- **Many goals.** There is no hard cap on FinalGoal or MilestoneGoal count. The Widget shows the first N current milestones based on family size and sort order.
- **Sequential milestone advancement.** Only the current active milestone accepts check-ins. Completing or archiving the current milestone automatically promotes the next one.
- **Accessibility.** Interactive controls have VoiceOver labels. The app list is keyboard-navigable. Deeper accessibility hardening is planned for v1.x.
