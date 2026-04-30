# Release Checklist

Run every check before tagging an open-source release. Initial releases are source-only tags with no signed build artifacts.

## Automated Checks

- [ ] Core tests pass: `swift test --package-path Packages/OneStepCore`
- [ ] App tests pass: `xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'`
- [ ] Widget target builds: `xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'`

## Manual App Checks — FinalGoal

- [ ] Create a FinalGoal with title, optional description, and optional calendar-day limit.
- [ ] Edit the FinalGoal's title, description, and calendar-day limit.
- [ ] Verify empty title is rejected.
- [ ] Complete a FinalGoal (requires all milestones done).
- [ ] Attempt to complete a FinalGoal with incomplete milestones — verify it is rejected.
- [ ] Archive a FinalGoal. Verify it moves to the archived section and its incomplete milestones are also archived.
- [ ] Reorder active FinalGoals via drag. Verify new order persists.

## Manual App Checks — MilestoneGoal

- [ ] Create a milestone within a FinalGoal with title and target completion days.
- [ ] Verify target completion days `0` is rejected.
- [ ] Verify target completion days below the completed count is rejected.
- [ ] Check in today on the current active milestone. Verify completed count increments.
- [ ] Undo today. Verify completed count decrements.
- [ ] Verify only the current active milestone (first active in sort order) accepts check-ins.
- [ ] Complete all days of the current milestone. Verify it auto-completes and the next milestone becomes current.
- [ ] Undo the last completion of an auto-completed milestone. Verify it reopens and becomes current again.
- [ ] Archive the current active milestone. Verify the next one becomes current.
- [ ] Edit a milestone's title and target completion days.

## Manual Widget Checks

- [ ] Small Widget shows 1 milestone.
- [ ] Medium Widget shows 3 milestones.
- [ ] Large Widget shows 5 milestones.
- [ ] Widget displays the current active milestone for each active FinalGoal, in sort order.
- [ ] Each Widget row shows the milestone title and parent FinalGoal title.
- [ ] Clicking an incomplete milestone in the Widget completes it without opening the app.
- [ ] Clicking an already-completed milestone in the Widget does nothing (idempotent).
- [ ] Clicking a stale Widget row for an archived milestone or FinalGoal does not create a completion.

## Data Checks

- [ ] Clean install: delete the app and Widget, rebuild, create a FinalGoal with milestones, verify store is created in the App Group container.
- [ ] Upgrade install (when applicable): build over an existing store, verify existing data is readable.
- [ ] Local store is readable by both the app and Widget after each operation.
- [ ] Cascade delete: delete a FinalGoal and verify its milestones and completions are removed.
- [ ] Cascade archive: archive a FinalGoal and verify incomplete milestones are also archived.

## Documentation Checks

- [ ] README build commands run without errors.
- [ ] Roadmap matches shipped scope for the release version.
- [ ] Privacy claims in `PRIVACY.md` are still true for the current codebase.
- [ ] `docs/troubleshooting/widget-app-group.md` reflects the current Widget/App Group setup.
- [ ] No unresolved `TODO`, `TBD`, or placeholder text in any documentation file.

## Release Tag

- [ ] Tag the release with a semver version (e.g., `v1.0.0`).
- [ ] Tag message summarizes the release scope.
- [ ] No unsigned build artifacts are attached unless the release checklist documents their limitations.
