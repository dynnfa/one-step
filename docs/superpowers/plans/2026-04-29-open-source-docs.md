# Open Source Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the open-source documentation layer described in `docs/superpowers/specs/2026-04-29-open-source-docs-design.md`.

**Architecture:** Keep historical MVP planning docs in `docs/plans/` as context, then add a current source-of-truth layer for open-source users and maintainers. Root-level docs introduce the project and contribution workflow; `docs/` files define product behavior, architecture, data migration, release QA, and troubleshooting.

**Tech Stack:** Markdown documentation for a macOS SwiftUI + WidgetKit app using `OneStepCore`, SwiftData, AppIntent, WidgetKit, and App Group storage.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-04-29-open-source-docs-design.md`
- Existing product plan: `docs/plans/one-step-design.md`
- Existing engineering plan: `docs/plans/one-step-engineering-plan.md`
- Existing test plan: `docs/plans/one-step-test-plan.md`
- Existing QA checklist: `docs/qa/widget-mvp-checklist.md`
- Existing Widget/App Group debug note: `docs/qa/2026-04-29-widget-goal-visibility-debug-note.md`
- README to update: `README.md`

## File Map

- Modify: `README.md` — concise public entry point and documentation index.
- Create: `ROADMAP.md` — open-source milestone scope and out-of-scope boundaries.
- Create: `CONTRIBUTING.md` — local setup, tests, PR expectations, signing notes.
- Create: `PRIVACY.md` — local-first privacy promise.
- Create: `docs/product/v1-product-spec.md` — v1 product behavior source of truth.
- Create: `docs/engineering/architecture.md` — app/widget/core/data boundaries.
- Create: `docs/engineering/data-schema-and-migration.md` — schema, invariants, migration policy.
- Create: `docs/qa/release-checklist.md` — open-source release gate.
- Create: `docs/troubleshooting/widget-app-group.md` — reusable Widget/App Group troubleshooting guide.

## Execution Order

1. Establish public root docs: roadmap, privacy, contributing guide.
2. Update README to link the documentation set.
3. Add product and engineering maintainer docs.
4. Add QA and troubleshooting docs.
5. Validate links, commands, scope consistency, and placeholder-free content.

## Task 1: Create Open-Source Roadmap

**Files:**
- Create: `ROADMAP.md`
- Reference: `docs/superpowers/specs/2026-04-29-open-source-docs-design.md`
- Reference: `docs/plans/one-step-design.md`

- [ ] Create `ROADMAP.md` with sections for `v1.0`, `v1.x`, `v2 Candidates`, and `Out of Scope`.
- [ ] Put stable local-first app + Widget behavior in `v1.0`.
- [ ] Put polish, accessibility hardening, QA hardening, and import/export in `v1.x`.
- [ ] Put iCloud sync and per-goal Widget configuration in `v2 Candidates`.
- [ ] Explicitly list reminders, social features, streak repair, task-manager expansion, accounts, and analytics as out of scope.
- [ ] Verify the roadmap does not promise commercial distribution or Mac App Store release.
- [ ] Commit with message: `docs: add open source roadmap`.

## Task 2: Create Privacy Policy

**Files:**
- Create: `PRIVACY.md`
- Reference: `README.md`
- Reference: `OneStep/App/AppConstants.swift`
- Reference: `OneStepWidget/AppConstants.swift`

- [ ] Create `PRIVACY.md` explaining that goal data is local to the user's Mac.
- [ ] State that One Step does not require an account.
- [ ] State that One Step does not upload goal data to a server.
- [ ] State that One Step does not include analytics or tracking.
- [ ] Explain that the app and Widget share local data through the App Group container.
- [ ] Add a note that future sync or export features must update `PRIVACY.md` before release.
- [ ] Commit with message: `docs: add privacy policy`.

## Task 3: Create Contributing Guide

**Files:**
- Create: `CONTRIBUTING.md`
- Reference: `README.md`
- Reference: `docs/qa/2026-04-29-widget-goal-visibility-debug-note.md`
- Reference: `docs/plans/one-step-test-plan.md`

- [ ] Create `CONTRIBUTING.md` with requirements: macOS 14+, Xcode 15+, Swift 5.9+.
- [ ] Add core test command: `swift test --package-path Packages/OneStepCore`.
- [ ] Add app test command: `xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'`.
- [ ] Add Widget build command: `xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'`.
- [ ] Add note to use `-allowProvisioningUpdates` when local App Group profiles need refreshing.
- [ ] Add PR expectations: update docs for behavior changes, include tests for repository/date/data behavior, and avoid scope expansion without updating roadmap/product spec.
- [ ] Add a short troubleshooting pointer to `docs/troubleshooting/widget-app-group.md`.
- [ ] Commit with message: `docs: add contributing guide`.

## Task 4: Update README Documentation Index

**Files:**
- Modify: `README.md`
- Reference: `ROADMAP.md`
- Reference: `CONTRIBUTING.md`
- Reference: `PRIVACY.md`

- [ ] Keep README concise as the public entry point.
- [ ] Preserve the product description, requirements, build commands, local Widget check, product boundaries, and data note.
- [ ] Add a `Documentation` section linking to `ROADMAP.md`, `CONTRIBUTING.md`, `PRIVACY.md`, `docs/product/v1-product-spec.md`, `docs/engineering/architecture.md`, `docs/engineering/data-schema-and-migration.md`, `docs/qa/release-checklist.md`, and `docs/troubleshooting/widget-app-group.md`.
- [ ] Make clear that `docs/plans/` contains historical planning context.
- [ ] Verify every new README link points to a planned or existing file.
- [ ] Commit with message: `docs: update readme documentation index`.

## Task 5: Create V1 Product Spec

**Files:**
- Create: `docs/product/v1-product-spec.md`
- Reference: `docs/plans/one-step-design.md`
- Reference: `OneStep/App/GoalStore.swift`
- Reference: `OneStepWidget/OneStepWidget.swift`
- Reference: `OneStepWidget/CompleteGoalIntent.swift`

- [ ] Create `docs/product/v1-product-spec.md`.
- [ ] Define the product promise: a Widget-first local tool for confirming daily progress on long-term goals.
- [ ] Define goal fields and lifecycle: create, edit, complete today, undo today from app, archive, reorder.
- [ ] Define Widget behavior: small shows 1 goal, medium shows 3 goals, large shows 5 goals, active manual order, idempotent completion, no Widget undo in v1.
- [ ] Define missed-day semantics: no backfill, no streak repair, no shame mechanics.
- [ ] Add concise expectations for empty states, error states, long text, many goals, and basic accessibility.
- [ ] State that this document supersedes `docs/plans/one-step-design.md` for current v1 behavior.
- [ ] Commit with message: `docs: add v1 product spec`.

## Task 6: Create Architecture Document

**Files:**
- Create: `docs/engineering/architecture.md`
- Reference: `docs/plans/one-step-engineering-plan.md`
- Reference: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift`
- Reference: `OneStepWidget/CompleteGoalIntent.swift`
- Reference: `OneStepWidget/OneStepTimelineProvider.swift`

- [ ] Create `docs/engineering/architecture.md`.
- [ ] Describe the three main areas: `OneStep/`, `OneStepWidget/`, and `Packages/OneStepCore/`.
- [ ] Include dependency direction: app and Widget depend on `OneStepCore`; `OneStepCore` does not depend on SwiftUI views or WidgetKit UI.
- [ ] Explain shared App Group persistence.
- [ ] Explain repository ownership of persistence rules.
- [ ] Explain snapshot structs as UI-facing data.
- [ ] Include the Widget tap flow: `Widget tap -> CompleteGoalIntent -> GoalRepository -> SwiftData/App Group -> Widget reload`.
- [ ] Add rules: do not duplicate persistence logic in app/widget, keep SwiftData models in core, render snapshots in UI.
- [ ] Commit with message: `docs: add architecture guide`.

## Task 7: Create Data Schema and Migration Policy

**Files:**
- Create: `docs/engineering/data-schema-and-migration.md`
- Reference: `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`
- Reference: `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`
- Reference: `Packages/OneStepCore/Sources/OneStepCore/Persistence/OneStepModelContainerFactory.swift`
- Reference: `Packages/OneStepCore/Sources/OneStepCore/Repositories/GoalRepository.swift`

- [ ] Create `docs/engineering/data-schema-and-migration.md`.
- [ ] Document current `Goal` fields and purpose.
- [ ] Document current `DailyCompletion` fields and `goalID + dayKey` uniqueness.
- [ ] Document App Group storage identifier `group.dev.dynnfa.OneStep`.
- [ ] Document invariants: one completion per goal/day, archived goals cannot be completed, progress uses completion count, target completion days cannot be below completed count.
- [ ] Define migration policy: schema can change before `v1.0`; after `v1.0`, schema changes need a migration note; destructive migration requires a manual backup/export path first.
- [ ] State that schema-affecting PRs must update this file.
- [ ] Commit with message: `docs: add data schema migration policy`.

## Task 8: Create Release Checklist

**Files:**
- Create: `docs/qa/release-checklist.md`
- Reference: `docs/qa/widget-mvp-checklist.md`
- Reference: `docs/plans/one-step-test-plan.md`

- [ ] Create `docs/qa/release-checklist.md`.
- [ ] Add automated checks for Swift package tests, Xcode app tests, and Widget target build.
- [ ] Add manual app checks: create, edit, complete today, undo today, archive, reorder.
- [ ] Add manual Widget checks: small, medium, large, app-created goal visibility, Widget completion write, repeated tap idempotency, stale archived tap safety.
- [ ] Add data checks: clean install, upgrade install when applicable, local store readable.
- [ ] Add documentation checks: README commands work, roadmap matches shipped scope, privacy claims remain true, troubleshooting doc is current.
- [ ] Note that initial open-source releases are source-only tags.
- [ ] Commit with message: `docs: add release checklist`.

## Task 9: Create Widget/App Group Troubleshooting Guide

**Files:**
- Create: `docs/troubleshooting/widget-app-group.md`
- Reference: `docs/qa/2026-04-29-widget-goal-visibility-debug-note.md`
- Reference: `OneStep/OneStep.entitlements`
- Reference: `OneStepWidget/OneStepWidget.entitlements`
- Reference: `OneStepWidget/OneStepTimelineProvider.swift`

- [ ] Create `docs/troubleshooting/widget-app-group.md`.
- [ ] Document symptom: Widget shows empty data even though app has goals.
- [ ] Add first checks: matching App Group identifier, entitlements include App Groups, provisioning profile includes App Groups.
- [ ] Add Console log guidance for Widget and AppIntent failures.
- [ ] Document common errors: SwiftData SQLite open failure and sandbox file-read-data denial.
- [ ] Document fixes: register App Groups, build with provisioning updates when needed, restart stale Widget extension process.
- [ ] Link back to the original dated QA note for historical detail.
- [ ] Commit with message: `docs: add widget app group troubleshooting`.

## Task 10: Final Documentation Validation

**Files:**
- Validate: `README.md`
- Validate: `ROADMAP.md`
- Validate: `CONTRIBUTING.md`
- Validate: `PRIVACY.md`
- Validate: `docs/product/v1-product-spec.md`
- Validate: `docs/engineering/architecture.md`
- Validate: `docs/engineering/data-schema-and-migration.md`
- Validate: `docs/qa/release-checklist.md`
- Validate: `docs/troubleshooting/widget-app-group.md`

- [ ] Run: `rg -n "TODO|TBD|placeholder|fill in|later" README.md ROADMAP.md CONTRIBUTING.md PRIVACY.md docs/product docs/engineering docs/qa/release-checklist.md docs/troubleshooting`
- [ ] Expected: no unresolved placeholder language.
- [ ] Run: `swift test --package-path Packages/OneStepCore`.
- [ ] Expected: tests pass.
- [ ] Run: `xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'`.
- [ ] Expected: tests pass, or document signing/provisioning reason if local environment blocks it.
- [ ] Run: `xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'`.
- [ ] Expected: build passes, or document signing/provisioning reason if local environment blocks it.
- [ ] Manually confirm README links resolve to existing files.
- [ ] Confirm `docs/plans/` remains historical context and is not rewritten.
- [ ] Confirm product spec, roadmap, privacy policy, and release checklist do not contradict each other.
- [ ] Commit any validation fixes with message: `docs: polish open source documentation`.

## Completion Criteria

- [ ] Root docs exist: `README.md`, `ROADMAP.md`, `CONTRIBUTING.md`, `PRIVACY.md`.
- [ ] Maintainer docs exist under `docs/product`, `docs/engineering`, `docs/qa`, and `docs/troubleshooting`.
- [ ] README links to the complete documentation set.
- [ ] New docs make open-source-only scope explicit.
- [ ] Data migration policy exists before first public release.
- [ ] Widget/App Group troubleshooting has a reusable guide.
- [ ] Validation commands have been run or blockers have been documented.

