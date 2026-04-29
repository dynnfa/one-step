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

The current app stores local data with SwiftData in the app group container `group.dev.dynnfa.OneStep`. Import/export is a possible v1.x improvement; iCloud sync is a possible v2 direction.

## Documentation

- [Roadmap](ROADMAP.md) — development scope and out-of-scope boundaries
- [Contributing](CONTRIBUTING.md) — build, test, and PR expectations
- [Privacy](PRIVACY.md) — local-first privacy promise
- [V1 Product Spec](docs/product/v1-product-spec.md) — current source of truth for product behavior
- [Architecture](docs/engineering/architecture.md) — app, Widget, core, and data boundaries
- [Data Schema and Migration](docs/engineering/data-schema-and-migration.md) — schema, invariants, migration policy
- [Release Checklist](docs/qa/release-checklist.md) — open-source release gate
- [Widget/App Group Troubleshooting](docs/troubleshooting/widget-app-group.md) — common Widget empty-data causes and fixes

The `docs/plans/` directory contains historical MVP planning context and is not the current source of truth.
