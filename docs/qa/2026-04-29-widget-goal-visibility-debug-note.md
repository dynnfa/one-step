# 2026-04-29 Widget Goal Visibility Debug Note

## 背景

当前项目中，主 App 可以创建 goal，但 Widget 无法显示主 App 中的 goal。Widget timeline provider 捕获错误后返回空数组，因此用户侧看到的是 Widget 没有数据。

## 现象

- 主 App 和 Widget 代码里都配置了同一个 App Group：`group.dev.dynnfa.OneStep`。
- 主 App entitlements 和 Widget entitlements 里也都声明了同一个 App Group。
- Widget timeline 加载失败后返回空 goals，界面表现为 Widget 空白或不显示主 App 数据。

## 排查过程

1. 先确认共享容器配置是否一致。

   检查 `OneStep/App/AppConstants.swift`、`OneStepWidget/AppConstants.swift`、`OneStep/OneStep.entitlements`、`OneStepWidget/OneStepWidget.entitlements`，确认 App Group 字符串一致，都是 `group.dev.dynnfa.OneStep`。

2. 增强 Widget 侧错误日志。

   原来的 Widget timeline 错误日志使用默认隐私级别，Console 中只看到：

   ```text
   [dev.dynnfa.OneStep:widget] Timeline load failed: <private>
   ```

   将 `OneStepWidget/OneStepTimelineProvider.swift` 中的日志改为公开输出错误描述：

   ```swift
   OneStepLog.widget.error("Timeline load failed: \(error.localizedDescription, privacy: .public)")
   ```

   重新构建并触发 Widget 后，日志显示：

   ```text
   Timeline load failed: The operation couldn't be completed. (SwiftData.SwiftDataError error 1.)
   ```

3. 继续查看 Widget 进程的系统日志。

   Widget 进程日志中出现 CoreData / SQLite 访问失败：

   ```text
   Sandbox access to file-read-data denied
   Failed to open '/Users/dynnfa/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite' for read/write access (Operation not permitted)
   NSCocoaErrorDomain Code=256
   NSSQLiteErrorDomain = 23
   ```

   这说明 Widget 找到了共享容器路径，但运行时没有权限打开共享 SQLite 文件。

4. 用 Xcode build/test 验证签名与 profile。

   普通 `xcodebuild test` 失败，提示主 App 和 Widget 的 provisioning profile 不支持 App Groups：

   ```text
   Provisioning profile "Mac Team Provisioning Profile: dev.dynnfa.OneStep.OneStepWidget" doesn't support the App Groups capability
   Provisioning profile ... doesn't include the com.apple.security.application-groups entitlement
   ```

   这一步确认了根因：项目文件和 entitlements 里声明了 App Group，但 Apple Developer / Xcode 自动签名生成的 provisioning profile 没有真正包含 App Groups capability。

## 根因

这是签名与授权问题，不是 Widget 查询逻辑问题。

在 macOS 15+ 的开发签名环境中，`group.` App Group 不能只写在 entitlements 文件里。运行时是否能访问 Group Container，还取决于 provisioning profile 是否包含 `com.apple.security.application-groups` entitlement，并且该 App Group 是否被注册到对应 App ID。

之前的 profile 没有 App Groups capability，所以 Widget 虽然拿到了共享容器路径，但 sandbox 不允许它打开共享 SQLite：

```text
/Users/dynnfa/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite
```

Widget timeline provider 捕获 SwiftData 打开 store 的错误后返回空 goals，于是表现为 Widget 无法显示主 App 中的 goal。

## 修改内容

### 1. 让 Xcode 自动注册并刷新 App Groups

在 `OneStep.xcodeproj/project.pbxproj` 中，给主 App 和 Widget 的 Debug / Release build settings 增加：

```text
REGISTER_APP_GROUPS = YES;
```

涉及 target：

- `OneStep`
- `OneStepWidget`

这样配合 automatic signing 和 `xcodebuild -allowProvisioningUpdates` 时，Xcode 会注册/更新 App Group，并生成包含 App Groups capability 的 provisioning profile。

注意：开始排查时，工作区里已经存在一些签名相关未提交改动，例如 `CODE_SIGNING_ALLOWED = YES`、`CODE_SIGN_STYLE = Automatic`、`DEVELOPMENT_TEAM = 4FU949C7U7` 等。本次关键新增点是 `REGISTER_APP_GROUPS = YES`，不要把所有签名 diff 都默认为同一轮手工修改。

### 2. 公开 Widget timeline 错误描述

在 `OneStepWidget/OneStepTimelineProvider.swift` 中，将 timeline 加载失败日志改为公开错误描述：

```swift
OneStepLog.widget.error("Timeline load failed: \(error.localizedDescription, privacy: .public)")
```

这让后续排查 Widget 空数据问题时，不需要先猜测 `<private>` 背后的错误。

## 验证记录

1. Swift Package 测试通过：

   ```sh
   swift test --package-path Packages/OneStepCore
   ```

   结果：27 个测试通过。

2. 使用 provisioning 更新重新运行 Xcode 测试：

   ```sh
   xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS' -allowProvisioningUpdates
   ```

   结果：通过，并生成/使用包含 App Groups 的新 profile。

3. 再次运行普通 Xcode 测试：

   ```sh
   xcodebuild test -project OneStep.xcodeproj -scheme OneStep -destination 'platform=macOS'
   ```

   结果：通过。

4. 构建 Widget target：

   ```sh
   xcodebuild build -project OneStep.xcodeproj -scheme OneStepWidget -destination 'platform=macOS' -allowProvisioningUpdates
   ```

   结果：通过。

5. 重启旧 Widget 进程后查看系统日志。

   旧的 Widget extension 进程仍可能带着旧签名运行，因此先结束旧进程，再让系统加载新构建的 extension。

   新日志中看到 Widget 进程成功消费 sandbox extension，不再出现 SwiftData / SQLite permission denied：

   ```text
   OneStepWidget[...] Consumed sandbox extension
   ```

   同时不再出现：

   ```text
   Timeline load failed: The operation couldn't be completed. (SwiftData.SwiftDataError error 1.)
   Sandbox access to file-read-data denied
   ```

## 结论

Widget 无法显示主 App 中 goal 的直接原因是 Widget 打不开 App Group 共享容器里的 SwiftData SQLite store。更底层的原因是 provisioning profile 没有包含 App Groups capability。

修复方式是：

- 确保主 App 和 Widget 使用同一个 App Group。
- 确保 entitlements 中声明 `com.apple.security.application-groups`。
- 在 Xcode project 中启用 `REGISTER_APP_GROUPS = YES`。
- 使用 `xcodebuild -allowProvisioningUpdates` 或 Xcode 自动签名刷新 profile。
- 重启旧 Widget extension 进程，避免系统继续运行旧签名版本。

后续如果 Widget 又出现空数据，应优先检查 Console 中的 `dev.dynnfa.OneStep:widget` 日志，以及是否存在 sandbox / SQLite 权限错误。
