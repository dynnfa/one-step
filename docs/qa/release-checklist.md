# Release Checklist

Run every check before tagging an open-source release. Initial releases are source-only tags with no signed build artifacts.

## Automated Checks

- [ ] Core tests pass: `swift test --package-path Packages/OneStepCore`
- [ ] App tests pass: `xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'`
- [ ] Widget target builds: `xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'`

## Manual App Checks

- [ ] Create a goal with title, daily action, and target completion days.
- [ ] Edit the goal's title, daily action, and target completion days.
- [ ] Verify empty title is rejected.
- [ ] Verify empty daily action is rejected.
- [ ] Verify target completion days `0` is rejected.
- [ ] Verify target completion days below the completed count is rejected.
- [ ] Complete today from the app. Verify completed count increments.
- [ ] Undo today from the app. Verify completed count decrements.
- [ ] Archive an active goal. Verify it moves to the archived section.
- [ ] Reorder active goals via drag. Verify new order persists.

## Manual Widget Checks

- [ ] Small Widget shows 1 goal.
- [ ] Medium Widget shows 3 goals.
- [ ] Large Widget shows 5 goals.
- [ ] Widget displays goals created by the app in the correct order.
- [ ] Clicking an incomplete goal in the Widget completes it without opening the app.
- [ ] Clicking an already-completed goal in the Widget does nothing (idempotent).
- [ ] Clicking a stale Widget row for an archived goal does not create a completion.

## Data Checks

- [ ] Clean install: delete the app and Widget, rebuild, create goals, verify store is created in the App Group container.
- [ ] Upgrade install (when applicable): build over an existing store, verify existing data is readable.
- [ ] Local store is readable by both the app and Widget after each operation.

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
