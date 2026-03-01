# 桌面版常驻图标快速访问功能 - 技术架构设计

**项目**: NotePassword Desktop Quick Access
**版本**: 1.0
**日期**: 2026-03-01
**状态**: 设计阶段

---

## 1. 架构概览

### 1.1 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                          User Interface Layer                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐              ┌──────────────────────┐    │
│  │   Main Window        │              │   Quick Access Panel │    │
│  │   (Flutter)          │              │   (Flutter)          │    │
│  │                      │              │                      │    │
│  │  - Desktop Home Page │              │  - Search Bar        │    │
│  │  - Detail Panel      │              │  - Password List     │    │
│  │  - Settings          │              │  - Detail Panel      │    │
│  └──────────────────────┘              └──────────────────────┘    │
│           │                                       │                  │
│           │                                       │                  │
├───────────┼───────────────────────────────────────┼──────────────────┤
│           │        Application Layer              │                  │
│           │                                       │                  │
│           └───────────────┬───────────────────────┘                  │
│                           │                                          │
│                  ┌────────▼────────┐                                │
│                  │  VaultProvider  │                                │
│                  │  (Riverpod)     │                                │
│                  │                 │                                │
│                  │  - VaultState   │                                │
│                  │  - Search       │                                │
│                  │  - Copy         │                                │
│                  └────────┬────────┘                                │
│                           │                                          │
├───────────────────────────┼──────────────────────────────────────────┤
│           Domain Layer    │                                          │
│                           │                                          │
│           ┌───────────────▼───────────────┐                         │
│           │      Use Cases                │                         │
│           │  - SearchVaultItemsUseCase    │                         │
│           │  - CopyPasswordUseCase        │                         │
│           │  - UnlockVaultUseCase         │                         │
│           └───────────────┬───────────────┘                         │
│                           │                                          │
├───────────────────────────┼──────────────────────────────────────────┤
│    Infrastructure Layer   │                                          │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────┐              │
│  │           Platform Integration                    │              │
│  │                                                    │              │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────┐│              │
│  │  │ Tray Manager │  │Window Manager│  │State Sync││              │
│  │  └──────────────┘  └──────────────┘  └─────────┘│              │
│  └────────────────────────────────────────────────────┘              │
│                           │                                          │
├───────────────────────────┼──────────────────────────────────────────┤
│      Native Layer         │                                          │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────┐              │
│  │         VaultStateManager (Singleton)             │              │
│  │         (macOS: Swift / Windows: C++)             │              │
│  │                                                    │              │
│  │  - sessionKey: String?                            │              │
│  │  - vaultData: Map<String, Any>                    │              │
│  │  - listeners: [EventSink]                         │              │
│  │                                                    │              │
│  │  Methods:                                         │              │
│  │  - updateState(state: Map)                        │              │
│  │  - getState() -> Map                              │              │
│  │  - addListener(sink: EventSink)                   │              │
│  └────────────────────────────────────────────────────┘              │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 核心组件设计

### 2.1 系统托盘管理器 (TrayManager)

**职责**: 管理系统托盘/菜单栏图标

**接口设计**:
```dart
class TrayManager {
  static final TrayManager _instance = TrayManager._internal();
  factory TrayManager() => _instance;
  TrayManager._internal();

  /// 初始化托盘图标
  Future<void> initialize() async;

  /// 获取托盘图标在屏幕上的位置
  Future<Offset> getIconPosition() async;

  /// 显示托盘图标
  Future<void> show() async;

  /// 隐藏托盘图标
  Future<void> hide() async;

  /// 销毁托盘图标
  Future<void> dispose() async;
}
```

**实现细节**:
- 使用 `tray_manager` 插件
- 监听图标点击事件
- 获取图标位置坐标（用于计算面板位置）
- 处理平台差异（macOS/Windows/Linux）

**平台差异处理**:
```dart
class TrayManager {
  Future<Offset> getIconPosition() async {
    if (Platform.isMacOS) {
      // macOS: 菜单栏在屏幕顶部
      return _getMacOSIconPosition();
    } else if (Platform.isWindows) {
      // Windows: 系统托盘在屏幕右下角
      return _getWindowsIconPosition();
    } else if (Platform.isLinux) {
      // Linux: 取决于桌面环境
      return _getLinuxIconPosition();
    }
    throw UnsupportedError('Platform not supported');
  }
}
```

---

### 2.2 快速访问窗口管理器 (QuickAccessWindowManager)

**职责**: 管理快速访问面板窗口的创建、显示、隐藏

**接口设计**:
```dart
class QuickAccessWindowManager {
  static final QuickAccessWindowManager _instance =
      QuickAccessWindowManager._internal();
  factory QuickAccessWindowManager() => _instance;
  QuickAccessWindowManager._internal();

  /// 显示快速访问面板
  Future<void> show() async;

  /// 隐藏快速访问面板
  Future<void> hide() async;

  /// 切换显示/隐藏
  Future<void> toggle() async;

  /// 是否正在显示
  bool get isShowing;

  /// 初始化窗口（预加载）
  Future<void> initialize() async;
}
```

**实现细节**:
```dart
class QuickAccessWindowManager {
  bool _isShowing = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 创建窗口但不显示
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(360, 480));
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);

    _isInitialized = true;
  }

  Future<void> show() async {
    if (_isShowing) return;

    // 如果未初始化，先初始化
    if (!_isInitialized) {
      await initialize();
    }

    // 获取托盘图标位置
    final iconPosition = await TrayManager().getIconPosition();

    // 计算面板位置
    final windowPosition = _calculateWindowPosition(
      iconPosition: iconPosition,
      windowSize: const Size(360, 480),
    );

    // 设置位置并显示
    await windowManager.setPosition(windowPosition);
    await windowManager.show();
    await windowManager.focus();

    _isShowing = true;

    // 监听点击外部区域
    _setupClickOutsideListener();
  }

  Offset _calculateWindowPosition({
    required Offset iconPosition,
    required Size windowSize,
  }) {
    // 获取屏幕尺寸
    final screenSize = _getScreenSize();

    double x = iconPosition.dx;
    double y = iconPosition.dy;

    // macOS: 图标在顶部，面板显示在下方
    if (Platform.isMacOS) {
      y = iconPosition.dy + 30; // 图标高度 + 间距
      x = iconPosition.dx - windowSize.width / 2; // 居中对齐
    }
    // Windows: 图标在右下角，面板显示在上方
    else if (Platform.isWindows) {
      y = iconPosition.dy - windowSize.height - 10;
      x = iconPosition.dx - windowSize.width / 2;
    }

    // 边界检测
    if (x < 0) x = 0;
    if (x + windowSize.width > screenSize.width) {
      x = screenSize.width - windowSize.width;
    }
    if (y < 0) y = 0;
    if (y + windowSize.height > screenSize.height) {
      y = screenSize.height - windowSize.height;
    }

    return Offset(x, y);
  }

  void _setupClickOutsideListener() {
    // 监听鼠标点击事件
    // 如果点击在窗口外部，关闭面板
  }
}
```

---

### 2.3 状态同步管理器 (VaultStateSync)

**职责**: 在主窗口和快速访问面板之间同步状态

**架构方案**: MethodChannel + EventChannel

**接口设计**:
```dart
class VaultStateSync {
  static const _methodChannel = MethodChannel('com.hedge.vault_sync');
  static const _eventChannel = EventChannel('com.hedge.vault_sync/events');

  Stream<VaultSyncEvent>? _eventStream;

  /// 更新共享状态
  Future<void> updateState(VaultState state) async {
    final stateMap = state.toJson();
    await _methodChannel.invokeMethod('updateState', stateMap);
  }

  /// 获取共享状态
  Future<VaultState?> getState() async {
    final stateMap = await _methodChannel.invokeMethod<Map>('getState');
    if (stateMap == null) return null;
    return VaultState.fromJson(Map<String, dynamic>.from(stateMap));
  }

  /// 监听状态变更
  Stream<VaultSyncEvent> watchStateChanges() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => VaultSyncEvent.fromJson(
              Map<String, dynamic>.from(event),
            ));
    return _eventStream!;
  }
}

/// 状态同步事件
class VaultSyncEvent {
  final VaultSyncEventType type;
  final VaultState? state;
  final String? itemId;

  VaultSyncEvent({
    required this.type,
    this.state,
    this.itemId,
  });

  factory VaultSyncEvent.fromJson(Map<String, dynamic> json) {
    return VaultSyncEvent(
      type: VaultSyncEventType.values.byName(json['type']),
      state: json['state'] != null
          ? VaultState.fromJson(json['state'])
          : null,
      itemId: json['itemId'],
    );
  }
}

enum VaultSyncEventType {
  stateUpdated,
  itemAdded,
  itemUpdated,
  itemDeleted,
  unlocked,
  locked,
}
```

**Native 层实现 (macOS Swift)**:
```swift
// VaultStateManager.swift
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

    func removeListener(_ sink: FlutterEventSink) {
        // 移除监听者
    }
}

// VaultSyncPlugin.swift
class VaultSyncPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.hedge.vault_sync",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.hedge.vault_sync/events",
            binaryMessenger: registrar.messenger()
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

    // FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        VaultStateManager.shared.addListener(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
```

**集成到 VaultProvider**:
```dart
class VaultNotifier extends StateNotifier<VaultState> {
  final VaultStateSync _stateSync;
  StreamSubscription? _syncSubscription;

  VaultNotifier(this._stateSync) : super(VaultState.initial()) {
    _initializeSync();
  }

  void _initializeSync() {
    // 监听状态变更
    _syncSubscription = _stateSync.watchStateChanges().listen((event) {
      switch (event.type) {
        case VaultSyncEventType.stateUpdated:
          if (event.state != null) {
            state = event.state!;
          }
          break;
        case VaultSyncEventType.itemAdded:
        case VaultSyncEventType.itemUpdated:
        case VaultSyncEventType.itemDeleted:
          // 重新加载状态
          _reloadState();
          break;
        case VaultSyncEventType.unlocked:
        case VaultSyncEventType.locked:
          // 更新解锁状态
          _updateLockState(event.type == VaultSyncEventType.unlocked);
          break;
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  // 当状态变更时，同步到 Native 层
  void _syncState() {
    _stateSync.updateState(state);
  }

  // 示例：添加密码项
  Future<void> addItem(VaultItem item) async {
    // 更新本地状态
    state = state.copyWith(
      items: [...state.items, item],
    );

    // 同步到 Native 层
    _syncState();
  }
}
```

---

### 2.4 快速访问面板 UI (QuickAccessPanel)

**组件结构**:
```
QuickAccessPanel
├── QASearchBar (搜索框)
├── QAPasswordList (密码列表)
│   └── QAPasswordListItem (列表项)
└── QADetailPanel (详情面板)
    ├── QADetailField (详情字段)
    └── QACopyButton (复制按钮)
```

**QuickAccessPanel 实现**:
```dart
class QuickAccessPanel extends ConsumerStatefulWidget {
  @override
  _QuickAccessPanelState createState() => _QuickAccessPanelState();
}

class _QuickAccessPanelState extends ConsumerState<QuickAccessPanel> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    // 面板打开后，搜索框自动获得焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final searchQuery = _searchController.text;

    // 过滤密码列表
    final filteredItems = searchQuery.isEmpty
        ? vaultState.items
        : vaultState.items.where((item) {
            final query = searchQuery.toLowerCase();
            return item.title.toLowerCase().contains(query) ||
                item.titlePinyin.toLowerCase().contains(query) ||
                (item.username?.toLowerCase().contains(query) ?? false);
          }).toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索框
            QASearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {});
              },
            ),

            // 密码列表
            Expanded(
              child: QAPasswordList(
                items: filteredItems,
                selectedId: _selectedItemId,
                onItemTap: (item) {
                  setState(() {
                    _selectedItemId = item.id;
                  });
                },
                onItemDoubleTap: (item) {
                  // 双击直接复制密码
                  ref.read(vaultProvider.notifier).copyPassword(item.id);
                  QuickAccessWindowManager().hide();
                },
              ),
            ),

            // 详情面板（如果有选中项）
            if (_selectedItemId != null)
              QADetailPanel(
                item: vaultState.items.firstWhere(
                  (item) => item.id == _selectedItemId,
                ),
                onClose: () {
                  setState(() {
                    _selectedItemId = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
```

**QAPasswordList 实现（含键盘导航）**:
```dart
class QAPasswordList extends StatefulWidget {
  final List<VaultItem> items;
  final String? selectedId;
  final Function(VaultItem) onItemTap;
  final Function(VaultItem)? onItemDoubleTap;

  const QAPasswordList({
    required this.items,
    required this.selectedId,
    required this.onItemTap,
    this.onItemDoubleTap,
  });

  @override
  _QAPasswordListState createState() => _QAPasswordListState();
}

class _QAPasswordListState extends State<QAPasswordList> {
  final _focusNode = FocusNode();
  int _keyboardSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: ListView.builder(
        itemCount: widget.items.length,
        itemExtent: 60.0, // 固定高度，优化性能
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = item.id == widget.selectedId;
          final isKeyboardSelected = index == _keyboardSelectedIndex;

          return QAPasswordListItem(
            item: item,
            isSelected: isSelected,
            isKeyboardFocused: isKeyboardSelected,
            onTap: () => widget.onItemTap(item),
            onDoubleTap: widget.onItemDoubleTap != null
                ? () => widget.onItemDoubleTap!(item)
                : null,
          );
        },
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    // 上下键导航
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _keyboardSelectedIndex =
            (_keyboardSelectedIndex + 1) % widget.items.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _keyboardSelectedIndex =
            (_keyboardSelectedIndex - 1 + widget.items.length) %
                widget.items.length;
      });
      return KeyEventResult.handled;
    }
    // 回车键显示详情
    else if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onItemTap(widget.items[_keyboardSelectedIndex]);
      return KeyEventResult.handled;
    }
    // ESC 键关闭面板
    else if (event.logicalKey == LogicalKeyboardKey.escape) {
      QuickAccessWindowManager().hide();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
```

---

## 3. 数据流设计

### 3.1 状态同步流程

```
┌─────────────────────────────────────────────────────────────┐
│                    用户操作                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              VaultNotifier (Flutter)                         │
│  - 更新本地状态 (state = newState)                          │
│  - 调用 _syncState()                                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           VaultStateSync (Flutter)                           │
│  - updateState(state)                                       │
│  - 调用 MethodChannel                                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│        VaultStateManager (Native - Singleton)                │
│  - 更新共享状态 (state = newState)                          │
│  - 广播到所有监听者 (eventSinks)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           EventChannel (Native → Flutter)                    │
│  - 发送状态变更事件                                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│        VaultStateSync.watchStateChanges()                    │
│  - 接收状态变更事件                                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           VaultNotifier (其他窗口)                           │
│  - 更新本地状态 (state = event.state)                       │
│  - UI 自动重建                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. 性能优化策略

### 4.1 冷启动优化

**目标**: < 500ms

**策略**:
1. **预加载窗口**: 应用启动时初始化面板窗口（但不显示）
2. **延迟加载**: 非核心功能延迟加载
3. **减少依赖**: 面板窗口只加载必要的依赖

**实现**:
```dart
// 在应用启动时预加载
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化主窗口
  await initializeMainWindow();

  // 预加载快速访问面板（后台初始化）
  QuickAccessWindowManager().initialize();

  runApp(MyApp());
}
```

### 4.2 热启动优化

**目标**: < 200ms

**策略**:
1. **保持窗口**: 面板关闭后不销毁窗口，只是隐藏
2. **缓存状态**: 缓存搜索结果和列表状态
3. **避免重建**: 使用 `const` 构造函数和 `StatelessWidget`

### 4.3 内存优化

**目标**: < 100MB

**策略**:
1. **共享资源**: 主窗口和面板共享 VaultProvider 状态
2. **懒加载列表**: 使用 `ListView.builder` 懒加载
3. **释放资源**: 面板长时间未使用时释放资源

### 4.4 搜索优化

**目标**: < 100ms (1000 条数据)

**策略**:
1. **防抖**: 搜索输入防抖 300ms
2. **Isolate**: 大量数据时在 Isolate 中搜索
3. **索引**: 预计算拼音索引

---

## 5. 错误处理和降级方案

### 5.1 系统托盘不可用

**检测**:
```dart
Future<bool> isTraySupported() async {
  try {
    await trayManager.setIcon('assets/icon.png');
    return true;
  } catch (e) {
    return false;
  }
}
```

**降级方案**:
- 在设置页面显示提示
- 提供全局快捷键打开主窗口
- 提供帮助文档

### 5.2 独立窗口创建失败

**降级方案**:
- 降级到 Overlay 方案
- 在主窗口内显示快速访问面板

### 5.3 状态同步失败

**降级方案**:
- 使用本地状态，不同步
- 定期轮询同步

---

## 6. 安全考虑

### 6.1 内存安全

- Session Key 存储在 Native 层，不暴露给 Flutter
- 面板关闭后不清空内存中的密码数据（性能考虑）
- 应用退出时清空所有敏感数据

### 6.2 窗口安全

- 面板窗口设置为 `setSkipTaskbar(true)`，不在任务栏显示
- 面板窗口设置为 `setAlwaysOnTop(true)`，始终置顶
- 点击外部区域自动关闭面板

---

## 7. 测试策略

### 7.1 单元测试

- VaultStateSync 测试
- WindowPositionCalculator 测试
- 键盘导航逻辑测试

### 7.2 集成测试

- 主窗口 ↔ 面板状态同步测试
- 系统托盘点击事件测试
- 窗口位置计算测试

### 7.3 性能测试

- 冷启动时间测试
- 热启动时间测试
- 内存占用测试
- 搜索响应时间测试

---

## 8. 部署和发布

### 8.1 平台特定配置

**macOS**:
- 配置 `Info.plist` 权限
- 配置 `Entitlements`
- 签名和公证

**Windows**:
- 配置 `manifest`
- 配置安装程序

**Linux**:
- 配置 `AppImage` 或 `Flatpak`
- 配置桌面文件

---

**文档版本**: 1.0
**最后更新**: 2026-03-01
**负责人**: 技术团队
