# V1 Product Spec

This document is the current source of truth for One Step v1 product behavior. For historical planning context, see `docs/plans/one-step-design.md`. When the two disagree, this document wins.

## Product Promise

One Step is a Widget-first local tool for confirming daily progress on long-term goals. The user creates a commitment — "study vocabulary for 30 minutes every day for 200 days" — puts it on the desktop as a Widget, and clicks to confirm each day's effort. The primary workflow happens on the desktop, not inside an app.

The product does not shame missed days, preserve fake streaks, or try to replace a task manager.

## Goal Model

A goal represents a long-term commitment.

Fields:

| Field | Type | Rules |
|-------|------|-------|
| Title | String | Non-empty after trim. Example: "Vocabulary". |
| Daily action | String | Non-empty after trim. Example: "Study 30 minutes". |
| Target completion days | Int | Must be > 0. Represents intended completed days, not calendar duration. Can be increased freely; can be decreased only down to the current completed count. |
| Start day | String (YYYY-MM-DD) | Set on creation. Locked after the first completion. |
| Sort order | Int | Manual ordering for display. Defaults to creation order. |
| Archived at | Date? | `nil` when active. Set when archived. |

## Goal Lifecycle

1. **Create.** User enters title, daily action, and target completion days. The goal appears in the active list and becomes available to the Widget.
2. **Edit.** User can change title, daily action, and target completion days. Start day locks after the first completion. Target days cannot drop below completed count.
3. **Complete today.** Mark that the user did the daily action on the current local day. Available from the main app and the Widget.
4. **Undo today.** Remove today's completion record. Available only from the main app. The Widget does not expose undo in v1.
5. **Archive.** Remove a goal from the active list. Archived goals leave the Widget, remain visible in the app's archived section, and cannot receive new completions.
6. **Reorder.** User drags goals into a preferred order. The Widget follows this order when selecting which goals to display.

## Widget Behavior

The Widget is the primary daily interface. It shows active goals in the user's manual sort order.

| Widget family | Goals shown |
|---------------|-------------|
| Small | 1 |
| Medium | 3 |
| Large | 5 |

Each visible goal displays:

- Goal title
- Daily action
- Today's completion state
- Completed days / target days

Interaction rules:

- Clicking an incomplete goal in the Widget completes it for today without opening the app.
- Clicking an already-completed goal in the Widget does nothing (idempotent).
- Undo is not available from the Widget in v1.
- Widget timeline refreshes after each completion. Refresh timing is controlled by the system and is not instantaneous.

Empty state: when no active goals exist, the Widget shows "Create a goal in the app."

## Missed-Day Semantics

- A missed day has no completion record. It is not backfilled, not repairable, and not highlighted.
- Progress counts completed days toward the target, not elapsed calendar days.
- The product does not display streaks, chains, or break counts. The emotional stance is: "I am still on the path," not "I failed."

## Edge Cases

- **Empty states.** First launch invites the user to create a goal. After the first goal is saved, the app briefly points toward adding the Widget.
- **Error states.** Repository errors surface as user-visible messages in the app. Widget errors are logged and result in empty data display rather than a crash.
- **Long text.** Goal titles and daily actions may be long. The app list and Widget rows should truncate gracefully without breaking layout.
- **Many goals.** There is no hard cap on goal count. The Widget shows the first N based on family size and sort order. The app list shows all goals.
- **Accessibility.** Interactive controls have VoiceOver labels. The app list is keyboard-navigable. Deeper accessibility hardening is planned for v1.x.
