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
| Color theme ID | String | User-selected color theme. Defaults to `blue`; preset IDs map to built-in colors. |
| Custom color hex | String? | `#RRGGBB` custom color when the theme ID is `custom`; otherwise `nil`. |
| Start day | String (YYYY-MM-DD) | Set on creation. |
| Sort order | Int | Manual ordering for display. |
| Archived at | Date? | `nil` when active. Set when the goal is completed, ended, or archived. |

### MilestoneGoal

Represents a sequential phase within a FinalGoal, such as "Finish vocabulary" or "Practice listening."

Fields:

| Field | Type | Rules |
|-------|------|-------|
| Title | String | Non-empty after trim. |
| Target completion times | Int? | Optional. `nil` means unlimited; finite values must be > 0. Represents intended completion count, not calendar duration. |
| Final goal ID | UUID | Parent FinalGoal. |
| Sort order | Int | Determines sequence within the FinalGoal. |
| Start day | String? (YYYY-MM-DD) | Set on first check-in. `nil` until then. |
| Completed at | Date? | Auto-set when a finite target reaches its completion count. Unlimited milestones do not auto-complete. |

### Active Milestones

Each `MilestoneGoal` stores explicit active state. One or more incomplete milestones can be active at the same time, and only active incomplete milestones can receive check-ins. When a milestone auto-completes, it becomes inactive; the user chooses which milestone becomes active next.

## FinalGoal Lifecycle

1. **Create.** User enters title, optional description, optional calendar-day limit, and a color theme. The FinalGoal appears in the sidebar and is available to the Widget through its milestones.
2. **Edit.** User can change title, description, calendar-day limit, and color theme.
3. **Complete/archive.** Available at any time. Sets `archivedAt`, removes the FinalGoal from active tracking, and removes its milestones from the Widget. Milestones are not archived; they are either incomplete or complete.
4. **Reorder.** User drags FinalGoals into a preferred order. The Widget follows this order.
5. **Delete.** Removes the FinalGoal, all its milestones, and all completions.

## MilestoneGoal Lifecycle

1. **Create.** User enters title and optional target completion times within a FinalGoal. The milestone is appended at the end of the sort order.
2. **Edit.** User can change title and optional target completion times. Finite targets cannot drop below completed count.
3. **Check in (complete today).** Mark daily effort on an active incomplete milestone. Available from the app and the Widget. Sets `startDayKey` on first check-in.
4. **Undo today.** Remove today's completion from the main app. If the milestone was auto-completed, undoing reopens it.
5. **Auto-complete.** When a finite target reaches its completion count, the milestone's `completedAt` is set. Unlimited milestones stay open until edited or deleted.
6. **Delete.** Removes the milestone and its completions.

## Widget Behavior

The Widget is the primary daily interface. It shows active incomplete milestones from active FinalGoals, in the user's manual sort order.

| Widget family | Milestones shown |
|---------------|-----------------|
| Small | Up to 2 |
| Medium | Up to 4 |
| Large | Up to 12 |

Each visible milestone displays:

- Milestone title
- Parent FinalGoal title
- Today's completion state
- Completed times / target times, or completed times for unlimited milestones

The completion icon uses the parent FinalGoal color. Milestone titles remain the system primary text color, and secondary text remains system secondary color for readability.

Interaction rules:

- Clicking an incomplete milestone in the Widget completes it for today without opening the app.
- Clicking an already-completed milestone does nothing (idempotent).
- Undo is not available from the Widget in v1.
- Widget timeline refreshes after each completion. Refresh timing is controlled by the system and is not instantaneous.

Empty state: when no active milestones exist, the Widget shows "Create a goal in the app."

## Missed-Day Semantics

- A missed day has no completion record. It is not backfilled, not repairable, and not highlighted.
- Progress counts completed times toward the target, not elapsed calendar days. Unlimited milestones show completed times without a total.
- The product does not display streaks, chains, or break counts. The emotional stance is: "I am still on the path," not "I failed."

## Edge Cases

- **Empty states.** First launch invites the user to create a FinalGoal. After the first FinalGoal is saved, the app briefly points toward adding the Widget.
- **Error states.** Repository errors surface as user-visible messages in the app. Widget errors are logged and result in empty data display rather than a crash.
- **Long text.** Titles and descriptions may be long. The app list and Widget rows truncate gracefully without breaking layout.
- **Color themes.** FinalGoal color applies as a title/icon accent in the sidebar, the FinalGoal detail header, and Widget completion icons. Milestone titles remain system primary text color. Invalid or missing theme values fall back to the default blue theme.
- **Many goals.** There is no hard cap on FinalGoal or MilestoneGoal count. The Widget shows the first N current milestones based on family size and final-goal sort order.
- **Milestone activation.** Only active incomplete milestones accept check-ins. Completing a milestone clears its active state; users choose the next active milestone.
- **Accessibility.** Interactive controls have VoiceOver labels. The app list is keyboard-navigable. Deeper accessibility hardening is planned for v1.x.
