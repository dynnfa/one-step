# Design: Open Source Product Documentation

Date: 2026-04-29
Branch: feature/one-step-mvp-scaffold
Status: PROPOSED

## Context

One Step has completed the MVP-level implementation path: a local-first macOS app, a Widget extension, a shared `OneStepCore` package, SwiftData persistence in an App Group container, goal creation, daily completion, undo from the app, archive, ordering, and Widget check-in.

The current documentation explains the MVP idea and the vertical-slice implementation well:

- `README.md` introduces the project and local build commands.
- `docs/plans/one-step-design.md` captures the original product direction.
- `docs/plans/one-step-engineering-plan.md` captures the MVP vertical-slice architecture.
- `docs/plans/one-step-test-plan.md` captures implementation and QA checks.
- `docs/qa/widget-mvp-checklist.md` captures manual MVP verification.
- `docs/qa/2026-04-29-widget-goal-visibility-debug-note.md` captures a real Widget/App Group signing failure and fix.

Those documents are valuable, but they are still MVP-oriented. The next phase is not commercial distribution; the product will be open source only. The documentation should therefore optimize for maintainability, contributor clarity, local data trust, and preserving the Widget-first product boundary.

## Goal

Create a lightweight open-source product documentation layer that becomes the current source of truth for future development.

The documentation should help a new contributor answer:

1. What is One Step, and what is it deliberately not?
2. How do I build, test, and manually verify the app and Widget?
3. Where are the app, Widget, shared core, persistence, and data boundaries?
4. What product behavior must remain stable for v1?
5. What local data model exists, and how should future migrations be handled?
6. What should be checked before tagging an open-source release?
7. How do I troubleshoot the common Widget/App Group failure mode?
8. What privacy promise does this project make?

## Non-Goals

- Do not add commercial distribution process.
- Do not plan Mac App Store submission.
- Do not require a paid release, analytics, accounts, telemetry, or remote services.
- Do not rewrite historical MVP planning docs.
- Do not create heavyweight governance, RFC, or maintainer processes before they are needed.
- Do not change production code as part of this documentation pass.

## Recommended Approach

Use a two-layer documentation system.

Root-level documents should serve first-time visitors and contributors. Documents under `docs/` should serve maintainers and future implementers.

This keeps the project approachable while giving the product enough structure to keep future contributions aligned.

## Document Map

### Root-Level Documents

#### `README.md`

Purpose: public project entry point.

The README should remain concise and point readers to deeper docs. It should include:

- A one-paragraph product description.
- Product boundaries: not a general task manager, not a streak repair system, not a reminder app.
- Requirements: macOS 14+, Xcode 15+, Swift 5.9+.
- Build and test commands.
- A short local Widget verification flow.
- Links to roadmap, contributing guide, privacy policy, product spec, architecture, release checklist, and troubleshooting docs.

The README should not become the full product spec.

#### `ROADMAP.md`

Purpose: define development scope across open-source milestones.

Suggested sections:

- `v1.0`: stable open-source local-first app and Widget.
- `v1.x`: polish, accessibility, QA hardening, import/export if chosen.
- `v2`: larger optional bets, such as iCloud sync or per-goal Widget configuration.
- `Out of Scope`: reminders, social features, streak repair, task-manager expansion, accounts, analytics.

The roadmap should explicitly separate committed v1 work from possible future ideas.

#### `CONTRIBUTING.md`

Purpose: help contributors build, test, and submit safe changes.

Suggested sections:

- Development requirements.
- Recommended setup.
- Test commands:
  - `swift test --package-path Packages/OneStepCore`
  - `xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'`
  - Widget build command when needed.
- App Group and signing notes.
- PR expectations:
  - Include tests for repository/date/data behavior.
  - Update docs when product behavior changes.
  - Avoid expanding product scope without updating the roadmap or product spec.
- Common local debugging paths.

#### `PRIVACY.md`

Purpose: make the local-first privacy promise explicit.

The privacy policy should say:

- Goal data is stored locally on the user's Mac.
- The app does not require an account.
- The app does not upload goal data to a server.
- The app does not include analytics or tracking.
- Widget and app share data through the local App Group container.
- Future sync or export features must update this document before release.

### Maintainer Documents

#### `docs/product/v1-product-spec.md`

Purpose: current source of truth for v1 product behavior.

Suggested sections:

- Product promise.
- User model: long-term goals, daily action, target completion days.
- Goal lifecycle:
  - create
  - edit
  - complete today
  - undo today from app
  - archive
  - reorder
- Widget behavior:
  - small shows 1 goal
  - medium shows 3 goals
  - large shows 5 goals
  - visible goals follow active manual order
  - Widget completion is idempotent
  - Widget does not support undo in v1
- Missed-day semantics:
  - no backfill
  - no streak repair
  - no shame mechanics
- Empty states and error states.
- Long text and many-goal behavior.
- Accessibility expectations.

This document should supersede the older MVP plan for product behavior while linking back to it as historical context.

#### `docs/engineering/architecture.md`

Purpose: explain the system boundaries clearly enough for contributors to make safe changes.

Suggested sections:

- Target layout:
  - `OneStep/` for macOS app UI and app-level state.
  - `OneStepWidget/` for WidgetKit and AppIntent code.
  - `Packages/OneStepCore/` for models, persistence, repository, snapshots, logging, and date semantics.
- Dependency direction:

```text
OneStep.app ───────────────┐
                           ▼
                     OneStepCore
                           ▲
OneStepWidgetExtension ────┘
```

- Shared App Group persistence.
- Repository as the persistence boundary.
- Snapshot structs as UI-facing data.
- Widget refresh and AppIntent flow:

```text
Widget tap -> CompleteGoalIntent -> GoalRepository -> SwiftData/App Group -> Widget reload
```

- Logging categories and where to look for failures.
- Architectural rules:
  - App and Widget should not duplicate persistence logic.
  - SwiftData models should stay inside `OneStepCore`.
  - UI should render snapshots instead of owning data rules.

#### `docs/engineering/data-schema-and-migration.md`

Purpose: prevent accidental data loss after the project becomes publicly usable.

Suggested sections:

- Current schema:
  - `Goal`
  - `DailyCompletion`
  - unique completion key by `goalID + dayKey`
- Stored location:
  - App Group container `group.dev.dynnfa.OneStep`
- Data invariants:
  - one completion per goal per local day
  - archived goals cannot be completed
  - progress uses completion count, not elapsed days
  - target completion days cannot be below completed count
- Public-release migration policy:
  - Before v1.0, schema changes may still be made deliberately.
  - After v1.0, schema changes require a documented migration note.
  - Any destructive migration must include a manual backup/export path first.
  - Schema-affecting PRs must update this document.
- Future import/export considerations.

#### `docs/qa/release-checklist.md`

Purpose: define the open-source release gate.

Suggested sections:

- Automated checks:
  - Swift package tests.
  - Xcode app tests.
  - Widget target build.
- Manual app checks:
  - create goal
  - edit goal
  - complete today
  - undo today
  - archive
  - reorder
- Manual Widget checks:
  - small, medium, large families
  - Widget reads app-created goals
  - Widget writes completion
  - repeated Widget tap is idempotent
  - stale archived goal tap does not mutate data
- Data checks:
  - clean install
  - upgrade install when applicable
  - local store remains readable
- Documentation checks:
  - README commands work
  - roadmap matches shipped scope
  - privacy policy still true
  - troubleshooting doc is current

#### `docs/troubleshooting/widget-app-group.md`

Purpose: turn the real debug note into a reusable guide.

Suggested sections:

- Symptom: Widget shows empty data even though app has goals.
- First checks:
  - App and Widget use the same App Group identifier.
  - Entitlements include `com.apple.security.application-groups`.
  - provisioning profile includes App Groups.
- Console log filters and expected categories.
- Common error:
  - SwiftData error opening SQLite store.
  - sandbox file-read-data denied.
- Fix:
  - enable/register App Groups.
  - build with provisioning updates when needed.
  - restart stale Widget extension process.
- Link to the original dated QA note for historical details.

## Existing Document Policy

Keep `docs/plans/` as historical planning material. Do not delete or rewrite it during this documentation pass.

New documents become the current source of truth:

- Product behavior: `docs/product/v1-product-spec.md`
- Architecture: `docs/engineering/architecture.md`
- Data model and migration: `docs/engineering/data-schema-and-migration.md`
- Release verification: `docs/qa/release-checklist.md`
- Contributor setup: `CONTRIBUTING.md`
- Public roadmap: `ROADMAP.md`
- Privacy promise: `PRIVACY.md`

When historical docs disagree with new docs, the new docs win.

## Implementation Order

1. Create `ROADMAP.md`.
2. Create `PRIVACY.md`.
3. Create `CONTRIBUTING.md`.
4. Update `README.md` to link to the new documentation set.
5. Create `docs/product/v1-product-spec.md`.
6. Create `docs/engineering/architecture.md`.
7. Create `docs/engineering/data-schema-and-migration.md`.
8. Create `docs/qa/release-checklist.md`.
9. Create `docs/troubleshooting/widget-app-group.md` by distilling the existing dated QA note.

This order makes the repository easier to understand early, then adds deeper maintainer references.

## Validation Plan

Documentation validation should include:

- Run all shell commands listed in README and CONTRIBUTING.
- Confirm every linked document path exists.
- Confirm the product spec does not contradict the roadmap.
- Confirm architecture and data docs match current code structure.
- Confirm privacy claims remain true for the current codebase.
- Confirm release checklist covers both automated and manual Widget verification.
- Search for unresolved placeholders such as `TODO` and `TBD`.

## Scope Decisions

Use these defaults while writing the actual docs:

1. Import/export belongs in `v1.x`, not `v1.0`, because it is useful for local-first trust but not required for the first stable open-source release.
2. Initial open-source releases should be source-only tags. Unsigned build artifacts can be added later only after the release checklist covers their limitations clearly.
3. Basic accessibility expectations belong in `v1.0`; deeper accessibility hardening belongs in `v1.x`.
4. The first README update does not require screenshots. Screenshots can be added after the UI stabilizes and should not block the documentation pass.

## Success Criteria

This documentation pass is successful when:

- A new contributor can build and test the project from README and CONTRIBUTING alone.
- A maintainer can tell which document owns product behavior, architecture, data migration, release QA, and troubleshooting.
- The open-source scope is clear enough to reject task-manager, reminder, analytics, account, or streak-repair expansions.
- Data model changes have an explicit migration policy before the first public release.
- Widget/App Group troubleshooting is no longer trapped in a dated debug note.
