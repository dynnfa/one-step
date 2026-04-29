# Contributing to One Step

## Requirements

- macOS 14 or newer
- Xcode 15 or newer
- Swift 5.9 or newer

## Build and Test

Run the shared core tests:

```bash
swift test --package-path Packages/OneStepCore
```

Run the app tests:

```bash
xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'
```

Build the Widget target:

```bash
xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS'
```

If App Group provisioning profiles need refreshing, add `-allowProvisioningUpdates` to the xcodebuild command.

## Pull Request Expectations

- **Add tests** for changes to repository logic, date handling, completion semantics, or data validation.
- **Update docs** when product behavior changes. If you change goal lifecycle, Widget display rules, or data schema, update the relevant file under `docs/product/`, `docs/engineering/`, or `docs/qa/`.
- **Do not expand product scope** without updating `ROADMAP.md` and `docs/product/v1-product-spec.md` first. If you are unsure whether a change is in scope, open an issue before writing code.
- **Keep persistence logic in `OneStepCore`.** The app and Widget should not duplicate storage reads or writes. See `docs/engineering/architecture.md`.

## Troubleshooting

If the Widget shows empty data after local changes, see `docs/troubleshooting/widget-app-group.md` for the common causes and fixes.
