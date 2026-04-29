# Roadmap

## v1.0 — Stable Local-First App and Widget

The first milestone is a working macOS desktop Widget that shows the user's long-term goals and lets them confirm daily progress with one click, no app launch required.

Included:

- Create, edit, archive, and reorder long-term goals
- Daily completion from the Widget via AppIntent
- Undo today's completion from the main app
- Small (1 goal), medium (3 goals), and large (5 goals) Widget families
- Manual sort order for active goals; Widget follows that order
- Idempotent Widget taps — repeated clicks on a completed goal do nothing
- Missed-day honesty: no backfill, no streak repair, no shame mechanics
- SwiftData persistence in a shared App Group container
- `OneStepCore` local package with repository, models, snapshot structs, date normalization, and unit tests
- Basic accessibility: VoiceOver labels on interactive controls, keyboard-navigable app list

## v1.x — Polish and Hardening

Work that improves v1 without changing the product boundary.

Candidates:

- Import/export for local data portability (JSON or similar)
- Accessibility hardening: dynamic type, improved contrast, VoiceOver flow testing
- QA hardening: additional edge-case tests, automated Widget snapshot verification
- First-run experience refinement
- Performance tuning for many-goal scenarios
- Optional notarized builds or Homebrew Cask distribution
- GitHub Actions CI on pull requests

Items move from candidates to committed when a specific PR or issue defines the scope.

## v2 — Optional Larger Bets

These are ideas, not commitments. Each requires its own design doc before work begins.

- iCloud sync for multi-device use
- Per-goal Widget configuration (separate from global sort order)
- Deeper local progress insights in the dashboard

## Out of Scope

One Step is not expanding into these areas:

- Reminders and push notifications
- Social features, sharing, or leaderboards
- Streak repair or backfill mechanics
- General task management (subtasks, projects, labels, due dates)
- User accounts or authentication
- Analytics, telemetry, or tracking
- Mac App Store distribution (unless sandboxing and review tradeoffs change)
