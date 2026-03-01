# 桌面版常驻图标快速访问功能 - 快速开始指南

**项目**: NotePassword Desktop Quick Access
**日期**: 2026-03-01
**适用人群**: 开发工程师

---

## 🚀 快速开始

### 第一步：创建开发分支

```bash
cd /Users/hardy/Work/note-password
git checkout -b feature/desktop-quick-access
```

---

## 📋 阶段 1：技术预研（Day 1-5）

### 任务 1.1：评估系统托盘插件（Day 1-2）

#### 1. 添加依赖

编辑 `pubspec.yaml`：

```yaml
dependencies:
  tray_manager: ^0.2.0
  window_manager: ^0.3.0
```

运行：
```bash
fvm flutter pub get
```

#### 2. 创建测试文件

创建 `lib/infrastructure/platform/tray_manager_test.dart`：

```dart
import 'package:tray_manager/tray_manager.dart';

class TrayManagerTest {
  Future<void> testTrayIcon() async {
    // 测试创建托盘图标
    await trayManager.setIcon('assets/icon.png');
    print('✅ 托盘图标创建成功');

    // 测试获取图标位置
    final bounds = await trayManager.getBounds();
    print('✅ 图标位置: ${bounds?.left}, ${bounds?.top}');

    // 测试点击事件
    trayManager.addListener(_TrayTestListener());
    print('✅ 点击事件监听器添加成功');
  }
}

class _TrayTestListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    print('✅ 托盘图标被点击');
  }

  @override
  void onTrayIconRightMouseDown() {
    print('✅ 托盘图标被右键点击');
  }
}
```

#### 3. 运行测试

在 `main.dart` 中添加测试代码：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 测试托盘管理器
  final trayTest = TrayManagerTest();
  await trayTest.testTrayIcon();

  runApp(MyApp());
}
```

运行：
```bash
fvm flutter run -d macos
```

#### 4. 验证清单

- [ ] 托盘图标是否正常显示？
- [ ] 能否获取图标位置坐标？
- [ ] 点击事件是否正常触发？
- [ ] macOS/Windows/Linux 是否都支持？

#### 5. 输出报告

创建 `docs/tech-research/tray-manager-evaluation.md`，记录：
- 测试结果（成功/失败）
- 性能数据（图标创建时间、事件响应时间）
- 兼容性问题
- 推荐方案

---

### 任务 1.2：验证独立窗口方案（Day 3-4）

#### 1. 创建测试文件

创建 `lib/infrastructure/platform/window_manager_test.dart`：

```dart
import 'package:window_manager/window_manager.dart';

class WindowManagerTest {
  Future<void> testQuickAccessWindow() async {
    // 测试创建无边框窗口
    await windowManager.setAsFrameless();
    print('✅ 无边框窗口创建成功');

    // 测试设置窗口大小
    await windowManager.setSize(const Size(360, 480));
    print('✅ 窗口大小设置成功');

    // 测试设置窗口位置
    await windowManager.setPosition(const Offset(100, 100));
    print('✅ 窗口位置设置成功');

    // 测试窗口置顶
    await windowManager.setAlwaysOnTop(true);
    print('✅ 窗口置顶设置成功');

    // 测试显示窗口
    await windowManager.show();
    print('✅ 窗口显示成功');

    // 测量窗口创建时间
    final stopwatch = Stopwatch()..start();
    await windowManager.hide();
    await windowManager.show();
    stopwatch.stop();
    print('✅ 窗口显示时间: ${stopwatch.elapsedMilliseconds}ms');
  }

  Future<void> testWindowPositionCalculation() async {
    // 测试窗口位置计算
    final iconPosition = Offset(1000, 50); // 模拟图标位置
    final windowSize = Size(360, 480);
    final screenSize = Size(1920, 1080);

    final windowPosition = _calculateWindowPosition(
      iconPosition: iconPosition,
      windowSize: windowSize,
      screenSize: screenSize,
    );

    print('✅ 计算的窗口位置: $windowPosition');
  }

  Offset _calculateWindowPosition({
    required Offset iconPosition,
    required Size windowSize,
    required Size screenSize,
  }) {
    double x = iconPosition.dx - windowSize.width / 2;
    double y = iconPosition.dy + 30;

    // 边界检测
    if (x < 0) x = 0;
    if (x + windowSize.width > screenSize.width) {
      x = screenSize.width - windowSize.width;
    }
    if (y + windowSize.height > screenSize.height) {
      y = iconPosition.dy - windowSize.height - 10;
    }

    return Offset(x, y);
  }
}
```

#### 2. 运行测试

```bash
fvm flutter run -d macos
```

#### 3. 验证清单

- [ ] 无边框窗口是否正常创建？
- [ ] 窗口大小是否正确（360x480）？
- [ ] 窗口位置计算是否正确？
- [ ] 窗口是否始终置顶？
- [ ] 窗口显示时间是否 < 200ms？
- [ ] 多显示器场景是否正常？

---

### 任务 1.3：验证状态同步方案（Day 5）

#### 1. 创建 Native 层代码（macOS）

创建 `macos/Runner/VaultStateManager.swift`：

```swift
import Foundation

class VaultStateManager {
    static let shared = VaultStateManager()

    private var state: [String: Any] = [:]
    private var eventSinks: [FlutterEventSink] = []

    private init() {}

    func updateState(_ newState: [String: Any]) {
        state = newState

        // 广播到所有监听者
        let event: [String: Any] = [
            "type": "stateUpdated",
            "state": newState
        ]

        for sink in eventSinks {
            sink(event)
        }
    }

    func getState() -> [String: Any] {
        return state
    }

    func addListener(_ sink: @escaping FlutterEventSink) {
        eventSinks.append(sink)
    }
}
```

创建 `macos/Runner/VaultSyncPlugin.swift`：

```swift
import FlutterMacOS

class VaultSyncPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.hedge.vault_sync",
            binaryMessenger: registrar.messenger
        )
        let eventChannel = FlutterEventChannel(
            name: "com.hedge.vault_sync/events",
            binaryMessenger: registrar.messenger
        )

        let instance = VaultSyncPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateState":
            if let state = call.arguments as? [String: Any] {
                VaultStateManager.shared.updateState(state)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: nil, details: nil))
            }

        case "getState":
            let state = VaultStateManager.shared.getState()
            result(state)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        VaultStateManager.shared.addListener(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
```

在 `macos/Runner/AppDelegate.swift` 中注册插件：

```swift
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // 注册 VaultSyncPlugin
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        VaultSyncPlugin.register(with: controller.registrar(forPlugin: "VaultSyncPlugin"))
    }
}
```

#### 2. 创建 Flutter 层代码

创建 `lib/infrastructure/platform/vault_state_sync.dart`：

```dart
import 'dart:async';
import 'package:flutter/services.dart';

class VaultStateSync {
  static const _methodChannel = MethodChannel('com.hedge.vault_sync');
  static const _eventChannel = EventChannel('com.hedge.vault_sync/events');

  Stream<Map<String, dynamic>>? _eventStream;

  /// 更新共享状态
  Future<void> updateState(Map<String, dynamic> state) async {
    await _methodChannel.invokeMethod('updateState', state);
  }

  /// 获取共享状态
  Future<Map<String, dynamic>?> getState() async {
    final result = await _methodChannel.invokeMethod<Map>('getState');
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  /// 监听状态变更
  Stream<Map<String, dynamic>> watchStateChanges() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
    return _eventStream!;
  }
}
```

#### 3. 创建测试代码

创建 `lib/infrastructure/platform/vault_state_sync_test.dart`：

```dart
class VaultStateSyncTest {
  final VaultStateSync _sync = VaultStateSync();

  Future<void> testStateSync() async {
    print('开始测试状态同步...');

    // 测试 1: 更新状态
    await _sync.updateState({'test': 'value1'});
    print('✅ 状态更新成功');

    // 测试 2: 读取状态
    final state = await _sync.getState();
    print('✅ 读取状态: $state');

    // 测试 3: 监听状态变更
    _sync.watchStateChanges().listen((event) {
      print('✅ 收到状态变更事件: $event');
    });

    // 测试 4: 从另一个窗口更新状态
    await Future.delayed(Duration(seconds: 2));
    await _sync.updateState({'test': 'value2'});
    print('✅ 状态同步测试完成');
  }
}
```

#### 4. 运行测试

```bash
fvm flutter run -d macos
```

#### 5. 验证清单

- [ ] MethodChannel 是否正常工作？
- [ ] EventChannel 是否正常工作？
- [ ] 状态更新是否实时同步？
- [ ] 多窗口场景是否正常？

---

## 📋 阶段 2：UI 设计（Day 6-8）

### 任务 2.1：创建 Figma 设计稿

#### 设计要求

1. **面板尺寸**: 360x480
2. **设计风格**: Cupertino（与移动端一致）
3. **支持模式**: 浅色/深色
4. **组件**:
   - 搜索框（高度 40px）
   - 密码列表（列表项高度 60px）
   - 详情区域（宽度 200px）

#### 设计清单

- [ ] 面板整体布局
- [ ] 搜索框样式
- [ ] 列表项样式（正常、选中、键盘焦点）
- [ ] 详情区域样式
- [ ] 空状态设计
- [ ] 加载状态设计
- [ ] 错误状态设计

---

## 📋 阶段 3：开发实现（Day 9-22）

### 任务 3.1：系统托盘集成（Day 9-11）

#### 1. 创建 TrayManager

创建 `lib/infrastructure/platform/tray_manager.dart`：

```dart
import 'package:tray_manager/tray_manager.dart';

class TrayManager {
  static final TrayManager _instance = TrayManager._internal();
  factory TrayManager() => _instance;
  TrayManager._internal();

  Future<void> initialize() async {
    await trayManager.setIcon('assets/icon.png');
    trayManager.addListener(_TrayListener());
  }

  Future<Offset> getIconPosition() async {
    final bounds = await trayManager.getBounds();
    if (bounds == null) return Offset.zero;
    return Offset(bounds.left, bounds.top);
  }
}

class _TrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    QuickAccessWindowManager().toggle();
  }
}
```

#### 2. 在 main.dart 中初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化托盘管理器
  await TrayManager().initialize();

  runApp(MyApp());
}
```

---

### 任务 3.2：独立窗口管理（Day 12-14）

创建 `lib/infrastructure/platform/quick_access_window_manager.dart`：

```dart
import 'package:window_manager/window_manager.dart';

class QuickAccessWindowManager {
  static final QuickAccessWindowManager _instance =
      QuickAccessWindowManager._internal();
  factory QuickAccessWindowManager() => _instance;
  QuickAccessWindowManager._internal();

  bool _isShowing = false;

  Future<void> show() async {
    if (_isShowing) return;

    final iconPosition = await TrayManager().getIconPosition();
    final windowPosition = _calculateWindowPosition(iconPosition);

    await windowManager.setSize(const Size(360, 480));
    await windowManager.setPosition(windowPosition);
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();

    _isShowing = true;
  }

  Future<void> hide() async {
    await windowManager.hide();
    _isShowing = false;
  }

  Future<void> toggle() async {
    if (_isShowing) {
      await hide();
    } else {
      await show();
    }
  }

  Offset _calculateWindowPosition(Offset iconPosition) {
    // 实现位置计算逻辑
    return Offset(iconPosition.dx - 180, iconPosition.dy + 30);
  }
}
```

---

### 任务 3.3：面板 UI 开发（Day 15-17）

创建 `lib/presentation/pages/desktop/quick_access_panel.dart`：

```dart
class QuickAccessPanel extends ConsumerStatefulWidget {
  @override
  _QuickAccessPanelState createState() => _QuickAccessPanelState();
}

class _QuickAccessPanelState extends ConsumerState<QuickAccessPanel> {
  final _searchController = TextEditingController();
  String? _selectedItemId;

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          // 搜索框
          _buildSearchBar(),

          // 密码列表
          Expanded(
            child: _buildPasswordList(vaultState.items),
          ),

          // 详情区域
          if (_selectedItemId != null)
            _buildDetailPanel(),
        ],
      ),
    );
  }
}
```

---

## 📋 阶段 4：测试和优化（Day 23-25）

### 功能测试清单

- [ ] 系统托盘图标显示/隐藏
- [ ] 面板打开/关闭
- [ ] 搜索功能
- [ ] 列表滚动
- [ ] 详情显示
- [ ] 快速复制
- [ ] 键盘导航
- [ ] 状态同步
- [ ] 多显示器支持

### 性能测试清单

- [ ] 冷启动时间 < 500ms
- [ ] 热启动时间 < 200ms
- [ ] 内存占用 < 100MB
- [ ] 搜索响应 < 100ms
- [ ] 列表滚动 60fps

---

## 🎯 成功标准

### 功能完整性
✅ 所有 MVP 功能已实现
✅ 通过功能测试（无阻塞性 bug）
✅ 支持 macOS/Windows/Linux

### 性能指标
✅ 热启动 < 200ms
✅ 冷启动 < 500ms
✅ 内存占用 < 100MB

### 用户体验
✅ 键盘导航流畅
✅ 状态同步实时
✅ 无明显卡顿

---

## 📚 参考文档

- PRD: `docs/desktop-quick-access-prd.md`
- 实施计划: `docs/desktop-quick-access-implementation-plan.md`
- 技术架构: `docs/desktop-quick-access-architecture.md`
- 项目总结: `docs/desktop-quick-access-summary.md`

---

## 🆘 遇到问题？

1. 查看技术架构文档
2. 查看实施计划中的风险管理
3. 联系技术架构师

---

**文档版本**: 1.0
**最后更新**: 2026-03-01
**适用人群**: 开发工程师
