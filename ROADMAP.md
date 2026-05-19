# Roadmap

## v1.0 — Current Local-First App and Widget

The first milestone is a working macOS desktop Widget that shows the user's long-term goals and lets them confirm daily progress with one click, no app launch required.

Implemented:

- Create, edit, archive/reactivate, delete, and reorder long-term goals
- Optional goal descriptions, calendar-day limits, and goal color themes, including custom colors
- Create, edit, delete, activate, and deactivate milestones inside each long-term goal
- One or more active incomplete milestones per goal; only active milestones can receive check-ins
- Finite milestone targets that auto-complete after the target completion count is reached
- Daily completion from the main app and the Widget via AppIntent
- Undo today's completion from the main app, including reopening an auto-completed milestone when appropriate
- Small (up to 2 milestones), medium (up to 4 milestones), and large (up to 12 milestones) Widget families
- Manual sort order for active goals; Widget follows that order and then milestone order
- Widget rows show milestone title, parent goal, today's completion state, and completion progress
- Idempotent Widget taps — repeated clicks on a completed goal do nothing
- Missed-day honesty: no backfill, no streak repair, no shame mechanics
- SwiftData persistence in a shared App Group container
- Local `.onestepbackup` export/import for data portability, with confirmation before replacing current data
- `OneStepCore` local package with repositories, models, backup documents, snapshot structs, date normalization, and unit tests
- Recent activity visualization for milestone completion history
- Basic accessibility: VoiceOver labels on interactive controls, keyboard-navigable app list

## v1.x — Polish and Hardening

Work that improves v1 without changing the product boundary.

Candidates:

- Backup UX hardening: clearer import failure recovery, sample backup validation, and compatibility checks for older backup schemas
- Accessibility hardening: dynamic type, improved contrast, VoiceOver flow testing
- QA hardening: additional edge-case tests, automated Widget snapshot verification
- First-run experience refinement, especially guiding users to activate milestones and add the Widget
- Performance tuning for many-goal scenarios
- Release hardening: optional notarized builds or Homebrew Cask distribution
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
