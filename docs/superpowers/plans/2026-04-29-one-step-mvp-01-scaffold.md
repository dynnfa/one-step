# One Step MVP 01 Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the macOS app target, Widget extension target, shared App Group entitlement, and empty `OneStepCore` Swift package.

**Architecture:** This plan only establishes project structure. It does not implement SwiftData, repository logic, app workflow, or final Widget UI. The output is a buildable app shell and a testable local Swift package that later plans can extend.

**Tech Stack:** Xcode project, macOS 14+, SwiftUI, WidgetKit extension, Swift Package Manager, XCTest.

---

## Agent Boundary

Execute only this scaffold plan. Stop after the scaffold builds and the smoke package test passes.

## Files

- Create: `OneStep.xcodeproj`
- Create: `OneStep/App/AppConstants.swift`
- Create: `OneStep/App/OneStepApp.swift`
- Create: `OneStep/Views/ContentView.swift`
- Create: `OneStep/OneStep.entitlements`
- Create: `OneStepWidget/OneStepWidgetBundle.swift`
- Create: `OneStepWidget/OneStepWidget.swift`
- Create: `OneStepWidget/OneStepWidget.entitlements`
- Create: `Packages/OneStepCore/Package.swift`
- Create: `Packages/OneStepCore/Sources/OneStepCore/OneStepCore.swift`
- Create: `Packages/OneStepCore/Tests/OneStepCoreTests/OneStepCoreSmokeTests.swift`

## Task 1: Xcode Project Shell

- [ ] **Step 1: Create project and Widget target**

Use Xcode:

```text
File > New > Project > macOS > App
Product Name: OneStep
Interface: SwiftUI
Language: Swift
Minimum Deployment: macOS 14.0
Location: /Users/dynnfa/TechPrivate/one-step
```

Then add:

```text
File > New > Target > macOS > Widget Extension
Product Name: OneStepWidget
Include Configuration Intent: off
```

- [ ] **Step 2: Enable App Group on both targets**

Add App Groups capability to `OneStep` and `OneStepWidget`:

```text
group.dev.dynnfa.OneStep
```

Confirm both entitlement files contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.dev.dynnfa.OneStep</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Add app constants**

Write `OneStep/App/AppConstants.swift`:

```swift
import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.dev.dynnfa.OneStep"
}
```

- [ ] **Step 4: Replace app entry and placeholder view**

Write `OneStep/App/OneStepApp.swift`:

```swift
import SwiftUI

@main
struct OneStepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
```

Write `OneStep/Views/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("One Step")
                .font(.headline)
                .padding()
        } detail: {
            Text("Create a long-term goal to begin.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 5: Verify Xcode targets**

Run:

```bash
xcodebuild -list -project OneStep.xcodeproj
```

Expected: output includes app and Widget targets or schemes for `OneStep` and `OneStepWidget`.

## Task 2: OneStepCore Package Shell

- [ ] **Step 1: Create folders**

Run:

```bash
mkdir -p Packages/OneStepCore/Sources/OneStepCore Packages/OneStepCore/Tests/OneStepCoreTests
```

- [ ] **Step 2: Write package manifest**

Write `Packages/OneStepCore/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OneStepCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "OneStepCore", targets: ["OneStepCore"])
    ],
    targets: [
        .target(name: "OneStepCore"),
        .testTarget(name: "OneStepCoreTests", dependencies: ["OneStepCore"])
    ]
)
```

- [ ] **Step 3: Add smoke symbol and test**

Write `Packages/OneStepCore/Sources/OneStepCore/OneStepCore.swift`:

```swift
public enum OneStepCore {
    public static let moduleName = "OneStepCore"
}
```

Write `Packages/OneStepCore/Tests/OneStepCoreTests/OneStepCoreSmokeTests.swift`:

```swift
import XCTest
@testable import OneStepCore

final class OneStepCoreSmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(OneStepCore.moduleName, "OneStepCore")
    }
}
```

- [ ] **Step 4: Run package tests**

Run:

```bash
swift test --package-path Packages/OneStepCore
```

Expected: `OneStepCoreSmokeTests.testModuleLoads` passes.

- [ ] **Step 5: Add local package dependency in Xcode**

In Xcode:

```text
Project OneStep > Package Dependencies > + > Add Local > Packages/OneStepCore
```

Add `OneStepCore` to both targets:

```text
OneStep
OneStepWidget
```

Confirm `OneStepCore` appears under Link Binary With Libraries for both targets.

- [ ] **Step 6: Build app shell**

Run:

```bash
xcodebuild -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' build
```

Expected: build succeeds.

- [ ] **Step 7: Commit**

```bash
git add OneStep.xcodeproj OneStep OneStepWidget Packages/OneStepCore
git commit -m "chore: scaffold one step app"
```

## Self-Review

- App target exists.
- Widget target exists.
- Both targets use `group.dev.dynnfa.OneStep`.
- `OneStepCore` package tests pass.
- No data model or repository code was added in this plan.
