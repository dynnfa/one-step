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
