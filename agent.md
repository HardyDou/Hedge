# Agent 经验总结与反思 (Lessons Learned)

## 1. 为什么 PRD 中已有的功能未被完整实现？

在 NotePassword 的第一阶段研发中，虽然 PRD 明确要求了"数据导入"、"搜索"等功能，但在实际开发过程中出现了遗漏。

### 经验总结：
*   **研发冲刺（Sprint）目标过窄**：作为 Agent，在执行"继续"或"下一步"指令时，往往倾向于优先构建"最小闭环"（MVP中的MVP），即增删改查的基础链路。这导致了 PRD 中定义的其他 P0 级功能（如导入、搜索）被推迟到了"未来"。
*   **缺乏 Checklist 强约束**：在开发过程中，没有将 PRD 拆解为一份可追踪的 Task List 并逐项对比。
*   **状态管理惯性**：在实现 UI 时，容易陷入"先跑通界面"的思维，而忽略了复杂的交互（如完整录入表单、国际化配置）。

## 2. 改进对策
*   **任务开始前强制对齐 PRD**：在每个阶段性任务开始前，必须重新扫描 PRD 的 `Functional Requirements` 章节，并在 `TodoWrite` 工具中显式列出所有涉及的功能点。
*   **模块化验证**：每个功能模块（如 Crypto, UI, Sync）完成后，应进行交叉检查。
*   **国际化优先**：所有新功能开发时，必须同步创建 ARB 键值对，避免后期重构压力。
*   **UI/UX 细节同步执行**：搜索、主题切换等核心交互功能应与列表功能同步实现，而非作为补丁。

---

## 3. 针对用户反馈的技术反思

### 3.1 模拟器生物识别失效
*   **原因**：iOS Simulator 默认不开启 FaceID 模拟。
*   **解决**：需要在虚拟机运行后，手动执行 `Features -> Face ID -> Enrolled`。

### 3.2 国际化 (i18n) 优先级
*   **教训**：在架构设计初期就应引入 `flutter_localizations`，否则后期重构所有硬编码字符串成本较高。

### 3.3 导入功能的复杂性
*   **分析**：1Password 导出的 `.1pux` 是一个包含加密 JSON 的压缩包，处理逻辑较重，应放入 Rust Core 中完成解析。

---

## 4. macOS 桌面端开发经验 (2026-02-27)

### 4.1 macOS 系统菜单 "Settings" 变灰无法点击

#### 问题描述
Flutter macOS 应用中，系统菜单里的 "Settings..." (⌘,) 是灰色不可点击。

#### 根因分析
1.  **MainMenu.xib**: Flutter 默认模板包含 `MainMenu.xib`，其中定义了 "Preferences..." 菜单项，但**没有绑定任何 Action 或 Target**。系统默认禁用了没有 Action 的菜单项。
2.  **Flutter AppDelegate**: 我们的 `AppDelegate` 试图通过代码修改菜单，但在 `applicationDidFinishLaunching` 中设置菜单可能**被 Flutter 的初始化流程覆盖**。
3.  **Responder Chain**: macOS 菜单项的启用状态取决于 Responder Chain 是否能响应其 Action。

#### 尝试过的方案 (均失败)
*   **方案 A**: 在 `applicationDidFinishLaunching` 中立即重建整个菜单 (完全代码构建)。
    *   结果：失败。Flutter 可能在之后重置了菜单，或者 XIB 加载优先级更高。
*   **方案 B**: 使用 `NSMenuItemValidation` 协议强制 `validateMenuItem` 返回 `true`。
    *   结果：失败。菜单项依然灰显。
*   **方案 C**: 手动查找并替换菜单项 (`patchAppMenu`)。
    *   结果：部分成功，但不稳定。

#### 最终解决方案
采用**修补 (Patch) 策略**：在应用启动后，通过 `DispatchQueue.main.async` 延迟执行修补逻辑，找到 `MainMenu.xib` 加载的现有 "Preferences..." 菜单项，**直接修改其属性**而非替换。

```swift
// AppDelegate.swift
override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // 1. 设置 MethodChannel
    if let controller = NSApplication.shared.windows.first?.contentViewController as? FlutterViewController {
        methodChannel = FlutterMethodChannel(name: "app.menu", binaryMessenger: controller.engine.binaryMessenger)
    }
    
    // 2. 延迟修补菜单项
    DispatchQueue.main.async { [weak self] in
        self?.setupPreferencesMenuItem()
    }
}

private func setupPreferencesMenuItem() {
    // 查找 App Menu 中的 Preferences 项 (Cmd+,)
    guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
    
    if let prefsItem = appMenu.items.first(where: { $0.keyEquivalent == "," }) {
        // 核心：显式设置 Target 和 Action
        prefsItem.target = self
        prefsItem.action = #selector(showPreferencesWindow(_:))
        prefsItem.isEnabled = true
    }
}

@IBAction func showPreferencesWindow(_ sender: Any?) {
    methodChannel?.invokeMethod("openSettings", arguments: nil)
}
```

#### 关键经验
*   **不要完全重建菜单**：尊重 XIB 加载的菜单，只修改需要的项。
*   **使用标准 Selector**：`showPreferencesWindow:` 是 macOS 标准的选择器。
*   **显式 Target**：必须设置 `target = self`。
*   **延迟执行**：使用 `DispatchQueue.main.async` 确保在系统初始化完成后执行。

### 4.2 桌面端图标不显示 (favicon)

#### 问题描述
桌面端密码列表中，网站图标的位置显示的是首字母 fallback，而非网站的 favicon。

#### 根因分析
**macOS App Sandbox 网络权限未开启**。
移动端默认有网络权限，但 macOS 需要在 Entitlements 文件中显式声明。

#### 解决方案
在 `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements` 中添加：
```xml
<key>com.apple.security.network.client</key>
<true/>
```

#### 关键经验
*   ** Entitlements 是 macOS 开发的第一道坎**：没有 `network.client`，应用无法访问互联网。
*   **热重载无效**：Entitlements 修改后必须**重新编译** (Stop & Run)。

### 4.3 Android 构建失败 (Kotlin Result 类型推断)

#### 问题描述
Android 构建失败，报错：`Cannot infer type for type parameter 'T'.`

#### 根因分析
代码中使用了 `Result(null)`，但由于导入了 Flutter 的 `MethodChannel.Result`，编译器无法推断 Kotlin 内置的 `kotlin.Result` 类型。

#### 解决方案
修改函数签名，避免类型推断歧义：
```kotlin
// 错误
private fun stopWatching(result: Result = Result(null))

// 正确
private fun stopWatching(result: Result?) {
    // ...
    result?.success(null)
}
```

### 4.4 桌面端布局调整

*   **侧边栏宽度**：从 350px 调整为 280px，更符合"黄金比例"审美。
*   **图标获取逻辑**：与移动端保持一致，使用 `CachedNetworkImage` 加载 `https://domain/favicon.ico`。

---

## 5. 本次会话开发记录 (Session Log 2026-02-26/2026-02-27)

### 4.1 代码修复
*   **detail_page.dart**: 修复语法错误 (缺失 `)`, 错误的 `IconButton` 嵌套)
*   **settings_page.dart**: 修复 `Divider` 引用错误

### 4.2 UI 优化
*   **edit_page.dart**: 按 iOS 设计规范重新设计，分组样式、圆角卡片
*   **add_item_page.dart**: 参考 edit_page 调整，保持一致的 iOS 风格
*   **detail_page.dart**:
    *   密码右侧功能按钮紧凑化 (32x32, 18px 图标)
    *   放大显示改为弹窗对话框 (不再横屏)
    *   使用 `TextPainter` 可靠检测密码是否超出屏幕宽度，自动切换横/竖向显示
*   **所有页面**: 完成 Material 到 Cupertino UI 的迁移
*   **设置页面**: 优化自动锁屏超时设置，使用 Action Sheet 替代 Slider，并添加“关闭”选项。
*   **设置页面**: 将重置密码页面从全屏模态弹窗改为底部 Action Sheet 弹窗。
*   **设置页面**: 修复设置页面 header 覆盖主页面内容的问题，通过调整 `ListView` padding 和 `SafeArea` 解决。
*   **设置页面**: 将设置页面的进入/退出动画调整为从左侧滑入/滑出。

### 4.3 功能改进
*   **URL 解析优化**: 支持不带 `http(s)://` 前缀的 URL 自动补全，确保 favicon 图标正常下载

### 4.4 多平台本地化
*   **iOS**: 创建 `Base.lproj/InfoPlist.strings` (英文) 和 `zh-Hans.lproj/InfoPlist.strings` (中文)
*   **Android**: 创建 `values/strings.xml` 和 `values-zh-rCN/strings.xml`
*   **macOS**: 同 iOS 结构
*   应用名称根据系统语言自动切换 ("密码本" / "Password Vault")

### 4.5 文档整理
*   删除多余的 review/approval 文档
*   合并 Build_Guide.md 到 Architecture_Design.md
*   移动 agent.md 到项目根目录

---

## 5. 国际化键值 (i18n Keys)

新增键值：
*   `basicInfo`: 基本信息
*   `titleHint`: 例如：Gmail、Netflix
*   `usernameHint`: 用户名或邮箱
*   `passwordHint`: 密码
*   `notesHint`: 备注信息...
*   `noAttachments`: 暂无附件
*   `vertical`: 纵向
*   `horizontal`: 横向
*   `copied`: 已复制
*   `copyPassword`: 复制密码

---

## 6. 密码全屏放大页面 (LargePasswordPage)

### 最终实现方案
使用 `SystemChrome.setPreferredOrientations` 真正旋转屏幕，而非模拟横屏。

**功能：**
- 点击放大按钮 → 进入全屏页面（竖屏）
- 点击旋转按钮 → 屏幕真正横过来
- 退出时 → 先恢复竖屏再退出，体验更平滑
- 横向模式时隐藏 AppBar 标题

**按钮：**
- 旋转屏幕按钮：切换横竖屏方向
- 复制密码按钮：一键复制

**布局：**
- 标题在上、密码在中间、按钮在下
- 每个字符 + 位号 上下结构显示
- 字符隔位换色

---

## 7. 密码详情页按钮优化

**优化内容：**
- 按钮统一为 28x28 大小
- 添加垂直居中对齐 `crossAxisAlignment: CrossAxisAlignment.center`
- 使用 `constraints: const BoxConstraints()` 移除额外间距
- 统一使用 iOS 蓝色 (0xFF007AFF)
- 统一图标大小为 18px

---

---

## 10. 最新计划 (结合 PRD)

### P0 (MVP) - 已完成 ✅
| 功能 | 状态 |
|------|------|
| 基础数据模型 (Vault/Item) | ✅ |
| 本地加密存储 (AES-256) | ✅ |
| iCloud Drive (iOS/Mac) & SAF (Android) 同步适配 | ✅ |
| 冲突解决机制 | ✅ |
| 数据导入 (Import) | ✅ |
| 生物识别解锁 (FaceID/Fingerprint) | ✅ |
| 批量删除 | ✅ |
| 自动锁屏 | ✅ |
| Material → Cupertino UI 迁移 | ✅ |
| 密码全屏放大显示 | ✅ |

### P0 待完成 🔧
| 功能 | 状态 |
|------|------|
| 真机崩溃调试 (iOS 详情页按 Home 崩溃) | 🔧 调试中 |
| 密码历史记录 | 🔧 待实现 |

### P1 计划
| 功能 | 说明 |
|------|------|
| Linux 版本适配 | 主流发行版支持 |
| 本地定期备份 | 自动备份功能 |

### P2 计划
| 功能 | 说明 |
|------|------|
| 附件/证书加密存储 | 扩展存储能力 |
| TOTP/2FA 验证码生成器 | 双因素认证支持 |
| Passkeys (FIDO2/WebAuthn) | 无密码登录支持 |

### P3 计划
| 功能 | 说明 |
|------|------|
| WebDAV 同步协议支持 | 私有云同步 |

---

## 9. 自动锁屏延迟实现 (2026-02-27)

### 9.1 背景
PRD 中要求"自动锁屏延迟"功能，设置中的数字未生效。需要添加 AppLifecycleObserver 监听应用进入后台并在后台计时。

### 9.2 方案探索过程

#### 方案 A: 自己实现 WidgetsBindingObserver
- 使用 `AppLifecycleState.paused`/`resumed` 监听
- 问题：在详情页、设置页返回时，锁屏遮罩被压在页面下方

#### 方案 B: 使用 OverlayEntry
- 问题：同样被压在页面下方

#### 方案 C: showDialog
- 之前版本能工作，但在详情页/设置页有问题

#### 方案 D: flutter_app_lock (最终方案)
- 成熟的 Flutter 锁屏包，125+ likes
- 使用 `AppLock` 包装 `CupertinoApp`
- 通过 `builder` 属性集成

### 9.3 最终实现

```dart
// main.dart
CupertinoApp(
  builder: (context, child) => AppLock(
    enabled: true,
    initialBackgroundLockLatency: Duration(seconds: vaultState.autoLockTimeout),
    builder: (context, arg) => child ?? const AuthGuard(),
    lockScreenBuilder: (lockContext) => Builder(
      builder: (builderContext) => UnlockPage(
        isLockOverlay: true,
        onUnlocked: () {
          AppLock.of(builderContext)!.didUnlock();
        },
      ),
    ),
  ),
  home: const AuthGuard(),
)
```

### 9.4 关键 API

| 功能 | 方法 |
|------|------|
| 设置延迟 | `initialBackgroundLockLatency` |
| 动态修改 | `AppLock.of(context)!.setBackgroundLockLatency(Duration)` |
| 解锁 | `AppLock.of(context)!.didUnlock()` |
| 启用/禁用 | `enable()` / `disable()` |

### 9.5 动态设置延迟

在设置页面中，用户选择延迟时间后，动态更新锁屏延迟：

```dart
// settings_page.dart
final notifier = ref.read(vaultProvider.notifier);
final appLock = AppLock.of(context);

notifier.setAutoLockTimeout(seconds);
appLock?.setBackgroundLockLatency(Duration(seconds: seconds));
```

### 9.6 UnlockPage 适配

添加 `isLockOverlay` 参数，区分启动时的解锁页面和锁屏遮罩：

```dart
class UnlockPage extends ConsumerStatefulWidget {
  final bool isLockOverlay;
  final VoidCallback? onUnlocked;
  // ...
}
```

### 9.7 经验总结

1. **不要自己实现锁屏**：使用成熟方案 `flutter_app_lock`
2. **CupertinoApp 兼容**：`AppLock` 需要在 `CupertinoApp.builder` 中使用
3. **Context 问题**：`AppLock.of(context)` 需要使用正确的 context，用 `Builder` 包装
4. **动态更新**：设置更改后调用 `setBackgroundLockLatency` 实时生效


