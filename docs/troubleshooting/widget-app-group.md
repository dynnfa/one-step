# Widget / App Group Troubleshooting

## Symptom

The Widget shows empty data ("Create a goal in the app.") even though the main app has active goals.

## First Checks

1. **App Group identifier matches.** Open `OneStep/App/AppConstants.swift` and `OneStepWidget/AppConstants.swift`. Both must contain the same identifier: `group.dev.dynnfa.OneStep`.

2. **Entitlements include App Groups.** Open `OneStep/OneStep.entitlements` and `OneStepWidget/OneStepWidget.entitlements`. Both must contain:

   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.dev.dynnfa.OneStep</string>
   </array>
   ```

3. **Provisioning profile includes App Groups.** If the profile was generated without the App Groups capability, the runtime sandbox blocks access to the shared container even though the entitlements file looks correct. See the signing fix below.

## Console Logs

Open Console.app and filter by subsystem `dev.dynnfa.OneStep`. Look for these categories:

- `widget` — timeline load failures
- `app-intent` — AppIntent execution failures
- `repository` — data-layer errors

Key error messages to watch for:

```text
Timeline load failed: The operation couldn't be completed. (SwiftData.SwiftDataError error 1.)
```

This usually means SwiftData cannot open the shared SQLite store. Check for sandbox errors next.

```text
Sandbox access to file-read-data denied
Failed to open '.../OneStep.sqlite' for read/write access (Operation not permitted)
```

This confirms the Widget process lacks permission to read the shared container. The root cause is a provisioning profile that does not include App Groups.

## Fixes

### Fix 1: Register App Groups in the Xcode project

In `OneStep.xcodeproj/project.pbxproj`, ensure both targets have:

```text
REGISTER_APP_GROUPS = YES;
```

This tells Xcode to register the App Group when generating provisioning profiles with automatic signing.

### Fix 2: Build with provisioning updates

```bash
xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget \
  -destination 'platform=macOS' -allowProvisioningUpdates
```

The `-allowProvisioningUpdates` flag lets Xcode refresh or regenerate the provisioning profile to include the App Groups capability.

### Fix 3: Restart the stale Widget extension process

After rebuilding, the old Widget extension process may still be running with the old signing. Kill it so the system loads the fresh build:

```bash
killall OneStepWidget
```

Or restart macOS. After the system loads the new extension, Console should show:

```text
OneStepWidget[...] Consumed sandbox extension
```

And the `Timeline load failed` / `Sandbox access denied` messages should stop.

## Historical Reference

For the full debug log of the original Widget/App Group signing failure and resolution, see `docs/qa/2026-04-29-widget-goal-visibility-debug-note.md`.
