# One Step MVP 06 Verification Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add developer docs, manual QA checklist, and run final MVP verification for core tests, app build, Widget build, and Widget-first workflow.

**Architecture:** Documentation should describe how to build and verify the local app without promising distribution artifacts. Verification should preserve the MVP boundary: local-first app and Widget only, no sync, no notarized releases, no import/export.

**Tech Stack:** Markdown, Swift Package Manager, Xcode build CLI, manual macOS Widget QA.

---

## Agent Boundary

Execute only docs and final verification. Code changes are allowed only to fix failures found by the listed commands.

## Files

- Create: `README.md`
- Create: `docs/qa/widget-mvp-checklist.md`
- Modify only failing implementation files if verification exposes a real build or behavior issue.

## Task 1: README

- [ ] **Step 1: Write README**

Write `README.md`:

```markdown
# One Step

One Step is a local-first macOS app for confirming daily progress on long-term goals from a desktop Widget.

## Requirements

- macOS 14 or newer
- Xcode 15 or newer
- Swift 5.9 or newer

## Build

```bash
swift test --package-path Packages/OneStepCore
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

## Local Widget Check

1. Open `OneStep.xcodeproj`.
2. Run the `OneStep` app scheme.
3. Create at least 5 goals.
4. Add the One Step Widget in small, medium, and large sizes.
5. Click an incomplete goal in the Widget.
6. Confirm the goal becomes completed today without opening the app.

## Product Boundaries

One Step is not a general task manager, streak repair tool, notes app, reminder system, or social habit tracker. Missed days remain missed. The Widget is the primary daily workflow.

## Data

The MVP stores local data with SwiftData in the app group container `group.dev.dynnfa.OneStep`. Import/export and iCloud sync are not part of the MVP.
```

## Task 2: Manual QA Checklist

- [ ] **Step 1: Write checklist**

Write `docs/qa/widget-mvp-checklist.md`:

```markdown
# One Step MVP QA Checklist

## Core Data

- [ ] Create `Vocabulary / Study 30 minutes / 200 days`.
- [ ] Confirm completed count starts at `0`.
- [ ] Complete today in the app.
- [ ] Confirm completed count becomes `1`.
- [ ] Undo today in the app.
- [ ] Confirm completed count returns to `0`.
- [ ] Complete the same goal twice from Widget.
- [ ] Confirm completed count remains `1`.

## Validation

- [ ] Empty title is rejected.
- [ ] Empty daily action is rejected.
- [ ] Target completion days `0` is rejected.
- [ ] Target completion days below completed count is rejected.

## Ordering

- [ ] Create 5 active goals.
- [ ] Reorder goals in the app.
- [ ] Confirm Widget order follows app order after timeline reload.

## Archive

- [ ] Archive an active goal.
- [ ] Confirm it leaves the active section.
- [ ] Confirm it appears in archived history.
- [ ] Confirm it disappears from Widget data.
- [ ] Click a stale Widget row for the archived goal.
- [ ] Confirm no new completion is created.

## Widget Families

- [ ] Small Widget shows 1 goal.
- [ ] Medium Widget shows 3 goals.
- [ ] Large Widget shows 5 goals.
- [ ] Widget rows do not clip badly with long titles or daily actions.
- [ ] Completed Widget rows show the completed state.

## App Group and Logs

- [ ] App and Widget both use `group.dev.dynnfa.OneStep`.
- [ ] Widget reads a goal created by the app.
- [ ] App reads a completion created by the Widget.
- [ ] Console logs distinguish store, repository, Widget timeline, and AppIntent failures.
```

- [ ] **Step 2: Commit docs**

```bash
git add README.md docs/qa/widget-mvp-checklist.md
git commit -m "docs: add mvp build and qa guide"
```

## Task 3: Final Verification

- [ ] **Step 1: Run core tests**

```bash
swift test --package-path Packages/OneStepCore
```

Expected: all tests pass.

- [ ] **Step 2: Build app**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

Expected: build succeeds.

- [ ] **Step 3: Build Widget extension**

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStepWidgetExtension -destination 'platform=macOS' build
```

If the scheme name differs, run:

```bash
xcodebuild -list -project OneStep.xcodeproj
```

Then build the listed Widget extension scheme.

- [ ] **Step 4: Run manual checklist**

Run every item in:

```text
docs/qa/widget-mvp-checklist.md
```

Expected: every item can be checked.

- [ ] **Step 5: Inspect git status**

```bash
git status --short
```

Expected: only intentional verification fixes remain unstaged.

- [ ] **Step 6: Commit verification fixes if needed**

If fixes were required:

```bash
git add OneStep OneStepWidget Packages/OneStepCore README.md docs/qa
git commit -m "fix: complete mvp verification"
```

If no fixes were required, do not create an empty commit.

## Self-Review

- README explains local build and Widget verification.
- QA checklist covers core data, validation, ordering, archive, Widget families, and App Group logs.
- Final verification commands match the master plan acceptance criteria.
