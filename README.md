# One Step

Daily planning, one tap at a time.

One Step is a local-first macOS app for tracking long-term goals through desktop Widgets. Set your goals, break them into milestones, and check off today's progress without ever opening the app.

## How It Works

1. **Set a goal.** Create a final goal and break it into sequential milestones.
2. **Check in daily.** Tap the milestone directly in the Widget. Done.
3. **Stay honest.** Missed days stay missed. No streak repair, no guilt mechanics, no social feed.

## Widget Sizes

| Size | Visible Milestones | Layout |
|------|--------------|--------|
| Small | Up to 2 | Single column |
| Medium | Up to 4 | Two-column grid |
| Large | Up to 12 | Two-column grid |

Each row shows the active milestone, its parent goal, and today's completion state. Widgets refresh every 15 minutes.

## Data Backup

One Step can export all local data from the Goals sidebar bottom toolbar:

- Choose **Export Data...** to save a `.onestepbackup` JSON file containing goals, milestones, archived state, and completion history.
- Choose **Import Data...** to restore a backup. Import replaces all current local data after confirmation.
- Keep exported backup files somewhere private because they contain your goal names, notes, and completion history.

## Requirements

- macOS 14+
- Xcode 15+
- Swift 5.9+

## Build

```bash
swift test --package-path Packages/OneStepCore
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

## Verify the Widget

1. Run the `OneStep` scheme.
2. Create at least 5 goals with milestones.
3. Add One Step Widget in small, medium, and large sizes.
4. Tap an incomplete milestone in the Widget.
5. Confirm it marks as completed — no app launch required.

## What One Step Is Not

Not a task manager. Not a streak app. Not a notes tool. Not a social habit tracker. One thing only: show up, tap, move on.

## Data

All data lives locally in SwiftData inside the app group container `group.dev.dynnfa.OneStep`. No accounts, no analytics, no telemetry. Import/export uses local JSON backup files; iCloud sync is a possible v2 direction.

## Documentation

- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)
- [Privacy](PRIVACY.md)
- [V1 Product Spec](docs/product/v1-product-spec.md)
- [Architecture](docs/engineering/architecture.md)
- [Data Schema & Migration](docs/engineering/data-schema-and-migration.md)
- [Release Checklist](docs/qa/release-checklist.md)
- [Widget Troubleshooting](docs/troubleshooting/widget-app-group.md)
