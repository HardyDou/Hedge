# 桌面版常驻图标快速访问功能 - 实施计划

**项目**: NotePassword Desktop Quick Access
**版本**: 1.0
**日期**: 2026-03-01
**状态**: 准备开始

---

## 项目概览

### 目标
为 NotePassword 桌面版添加常驻图标快速访问功能，用户可以通过系统托盘/菜单栏图标快速搜索和复制密码，无需打开主窗口。

### 关键指标
- 首次使用率 > 50%（30 天内）
- 7 日留存率 > 30%
- 热启动 < 200ms，冷启动 < 500ms
- 内存占用 < 100MB

### 预计工期
- 技术预研：3-5 天
- UI 设计：2-3 天
- 开发实现：10-12 天
- 测试优化：2-3 天
- **总计：17-23 天（约 3-4 周）**

---

## 阶段 1：技术预研（3-5 天）

### 任务 1.1：系统托盘插件评估（1-2 天）

**目标**: 选择合适的系统托盘/菜单栏插件

**候选插件**:
1. **tray_manager** (推荐)
   - GitHub: https://github.com/leanflutter/tray_manager
   - 优点：活跃维护，支持 macOS/Windows/Linux
   - 需验证：图标点击事件、位置获取

2. **system_tray**
   - GitHub: https://github.com/antler119/system_tray
   - 优点：API 简单
   - 需验证：跨平台兼容性

**验证内容**:
- [ ] 创建系统托盘/菜单栏图标
- [ ] 监听图标点击事件
- [ ] 获取图标在屏幕上的位置坐标
- [ ] 测试 macOS/Windows/Linux 兼容性
- [ ] 测试图标显示/隐藏
- [ ] 测试应用退出时图标自动移除

**输出**:
- 插件选型报告（包含测试结果、性能数据、推荐方案）

---

### 任务 1.2：独立窗口方案验证（1-2 天）

**目标**: 验证使用 `window_manager` 创建独立窗口的可行性

**验证内容**:
- [ ] 创建无边框独立窗口
- [ ] 设置窗口大小（360x480）
- [ ] 设置窗口位置（根据图标坐标计算）
- [ ] 实现窗口置顶（always on top）
- [ ] 实现点击外部区域关闭窗口
- [ ] 测试多显示器场景
- [ ] 测试窗口位置边界处理（靠近屏幕边缘）
- [ ] 测量窗口创建时间（冷启动/热启动）
- [ ] 测量内存占用

**技术要点**:
```dart
// 示例代码
import 'package:window_manager/window_manager.dart';

Future<void> createQuickAccessWindow() async {
  // 创建无边框窗口
  await windowManager.setAsFrameless();

  // 设置窗口大小
  await windowManager.setSize(Size(360, 480));

  // 设置窗口位置（根据托盘图标位置计算）
  final iconPosition = await getTrayIconPosition();
  await windowManager.setPosition(
    Offset(iconPosition.dx, iconPosition.dy + 30)
  );

  // 设置窗口置顶
  await windowManager.setAlwaysOnTop(true);

  // 显示窗口
  await windowManager.show();
}
```

**输出**:
- 独立窗口技术验证报告（包含性能数据、边界情况处理方案）

---

### 任务 1.3：多窗口状态同步方案验证（1-2 天）

**目标**: 验证主窗口和面板窗口之间的状态同步方案

**方案 A（推荐）**: MethodChannel + EventChannel

**架构设计**:
```
┌─────────────────────────────────────────────────────────┐
│                    Native Layer (macOS/Windows)          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         VaultStateManager (Singleton)            │   │
│  │  - sessionKey: String?                           │   │
│  │  - vaultData: Map<String, Any>                   │   │
│  │  - listeners: [EventSink]                        │   │
│  └─────────────────────────────────────────────────┘   │
│           ↑                              ↑               │
│           │ MethodChannel                │ EventChannel │
│           │                              │               │
└───────────┼──────────────────────────────┼───────────────┘
            │                              │
    ┌───────┴────────┐            ┌───────┴────────┐
    │  Main Window   │            │  Panel Window  │
    │  (Flutter)     │            │  (Flutter)     │
    │                │            │                │
    │  VaultProvider │            │  VaultProvider │
    └────────────────┘            └────────────────┘
```

**验证内容**:
- [ ] 创建 Native 层单例（macOS: Swift, Windows: C++）
- [ ] 实现 MethodChannel 接口（读取/写入状态）
- [ ] 实现 EventChannel 接口（广播状态变更）
- [ ] 在主窗口中更新状态，验证面板窗口是否同步
- [ ] 在面板窗口中更新状态，验证主窗口是否同步
- [ ] 测试解锁状态同步
- [ ] 测试密码列表同步（新增、编辑、删除）

**技术要点**:
```dart
// Flutter 端
class VaultStateSync {
  static const platform = MethodChannel('com.hedge.vault_sync');
  static const eventChannel = EventChannel('com.hedge.vault_sync/events');

  // 读取共享状态
  Future<Map<String, dynamic>> getSharedState() async {
    return await platform.invokeMethod('getState');
  }

  // 更新共享状态
  Future<void> updateSharedState(Map<String, dynamic> state) async {
    await platform.invokeMethod('updateState', state);
  }

  // 监听状态变更
  Stream<Map<String, dynamic>> watchStateChanges() {
    return eventChannel.receiveBroadcastStream();
  }
}
```

**方案 B（备选）**: 单 Flutter 实例 + Overlay

如果方案 A 复杂度过高，可以降级到此方案：
- 面板使用 Overlay 在主窗口上层显示
- 状态直接共享，无需 IPC
- 缺点：依赖主窗口，无法真正"独立运行"

**输出**:
- 状态同步方案验证报告（包含性能数据、推荐方案）

---

### 任务 1.4：性能基准测试（0.5-1 天）

**目标**: 建立性能基准，确保满足指标要求

**测试内容**:
- [ ] 冷启动时间（首次打开面板）
- [ ] 热启动时间（再次打开面板）
- [ ] 内存占用（独立窗口方案）
- [ ] 搜索响应时间（1000 条数据）
- [ ] 列表滚动帧率

**测试环境**:
- macOS 12.0+ (M1/Intel)
- Windows 10+
- Linux Ubuntu 20.04+

**输出**:
- 性能基准测试报告

---

## 阶段 2：UI 设计（2-3 天）

### 任务 2.1：面板 UI 设计（1-1.5 天）

**设计内容**:
- [ ] 面板整体布局（360x480）
- [ ] 搜索框样式（高度 40px）
- [ ] 列表项样式（高度约 60px）
- [ ] 详情区域样式（宽度 200px 或全宽）
- [ ] 空状态设计
- [ ] 加载状态设计

**设计规范**:
- 遵循 Cupertino 设计风格
- 与移动端保持一致的视觉语言
- 支持浅色/深色模式

**输出**:
- Figma 设计稿
- 设计规范文档

---

### 任务 2.2：键盘焦点状态设计（0.5-1 天）

**设计内容**:
- [ ] 搜索框焦点状态
- [ ] 列表项选中状态
- [ ] 列表项键盘焦点状态
- [ ] 详情区域焦点状态
- [ ] 按钮焦点状态

**输出**:
- 焦点状态设计稿

---

### 任务 2.3：错误和边界状态设计（0.5 天）

**设计内容**:
- [ ] 密码库为空
- [ ] 搜索无结果
- [ ] 解锁失败
- [ ] 网络错误（如果涉及同步）
- [ ] 系统托盘不可用提示

**输出**:
- 错误状态设计稿

---

## 阶段 3：开发实现（10-12 天）

### 任务 3.1：系统托盘/菜单栏集成（2-3 天）

**开发内容**:
- [ ] 集成选定的系统托盘插件
- [ ] 创建托盘图标（使用应用主图标）
- [ ] 监听图标点击事件
- [ ] 获取图标位置坐标
- [ ] 实现图标显示/隐藏逻辑
- [ ] 处理应用退出时的清理

**文件结构**:
```
lib/
├── infrastructure/
│   └── platform/
│       ├── tray_manager.dart          # 托盘管理器
│       └── tray_icon_position.dart    # 图标位置获取
```

**关键代码**:
```dart
class TrayManager {
  static final TrayManager _instance = TrayManager._internal();
  factory TrayManager() => _instance;
  TrayManager._internal();

  Future<void> initialize() async {
    await trayManager.setIcon('assets/icon.png');
    trayManager.addListener(_TrayListener());
  }

  Future<Offset> getIconPosition() async {
    // 获取托盘图标在屏幕上的位置
  }
}

class _TrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    // 打开快速访问面板
    QuickAccessWindowManager().show();
  }
}
```

---

### 任务 3.2：独立窗口创建和定位（2-3 天）

**开发内容**:
- [ ] 创建独立窗口管理器
- [ ] 实现窗口创建逻辑
- [ ] 实现窗口位置计算（根据图标位置）
- [ ] 实现边界检测（屏幕边缘处理）
- [ ] 实现多显示器支持
- [ ] 实现点击外部区域关闭
- [ ] 实现 ESC 键关闭

**文件结构**:
```
lib/
├── infrastructure/
│   └── platform/
│       ├── quick_access_window_manager.dart  # 窗口管理器
│       └── window_position_calculator.dart   # 位置计算
```

**关键代码**:
```dart
class QuickAccessWindowManager {
  static final QuickAccessWindowManager _instance =
      QuickAccessWindowManager._internal();
  factory QuickAccessWindowManager() => _instance;
  QuickAccessWindowManager._internal();

  bool _isShowing = false;

  Future<void> show() async {
    if (_isShowing) return;

    // 获取托盘图标位置
    final iconPosition = await TrayManager().getIconPosition();

    // 计算面板位置
    final windowPosition = WindowPositionCalculator.calculate(
      iconPosition: iconPosition,
      windowSize: Size(360, 480),
    );

    // 创建/显示窗口
    await windowManager.setSize(Size(360, 480));
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
}
```

---

### 任务 3.3：面板 UI 开发（2-3 天）

**开发内容**:
- [ ] 创建面板主页面
- [ ] 实现搜索框
- [ ] 实现密码列表
- [ ] 实现详情区域
- [ ] 实现空状态
- [ ] 实现加载状态
- [ ] 实现错误状态

**文件结构**:
```
lib/
├── presentation/
│   ├── pages/
│   │   └── desktop/
│   │       └── quick_access_panel.dart       # 面板主页面
│   └── widgets/
│       └── quick_access/
│           ├── qa_search_bar.dart            # 搜索框
│           ├── qa_password_list.dart         # 密码列表
│           ├── qa_detail_panel.dart          # 详情区域
│           └── qa_empty_state.dart           # 空状态
```

**关键代码**:
```dart
class QuickAccessPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Column(
        children: [
          // 搜索框
          QASearchBar(
            onChanged: (query) {
              ref.read(quickAccessSearchProvider.notifier).search(query);
            },
          ),

          // 密码列表
          Expanded(
            child: QAPasswordList(
              items: vaultState.filteredItems,
              selectedId: ref.watch(selectedItemIdProvider),
              onItemTap: (item) {
                ref.read(selectedItemIdProvider.notifier).state = item.id;
              },
            ),
          ),

          // 详情区域（如果有选中项）
          if (ref.watch(selectedItemIdProvider) != null)
            QADetailPanel(
              item: vaultState.getItemById(
                ref.watch(selectedItemIdProvider)!
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### 任务 3.4：键盘导航实现（1-2 天）

**开发内容**:
- [ ] 实现上下键选择列表项
- [ ] 实现回车键显示详情
- [ ] 实现 ESC 键关闭详情/面板
- [ ] 实现 Tab 键切换焦点
- [ ] 实现 Cmd/Ctrl+C 快速复制
- [ ] 实现 Cmd/Ctrl+数字键快速复制
- [ ] 实现焦点管理

**关键代码**:
```dart
class QAPasswordList extends StatefulWidget {
  @override
  _QAPasswordListState createState() => _QAPasswordListState();
}

class _QAPasswordListState extends State<QAPasswordList> {
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1) % widget.items.length;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedIndex = (_selectedIndex - 1) % widget.items.length;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onItemTap(widget.items[_selectedIndex]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return _buildListItem(widget.items[index], index == _selectedIndex);
        },
      ),
    );
  }
}
```

---

### 任务 3.5：状态同步实现（2-3 天）

**开发内容**:
- [ ] 实现 Native 层状态管理器（macOS/Windows）
- [ ] 实现 MethodChannel 接口
- [ ] 实现 EventChannel 接口
- [ ] 集成到 VaultProvider
- [ ] 测试主窗口 → 面板同步
- [ ] 测试面板 → 主窗口同步
- [ ] 测试解锁状态同步

**文件结构**:
```
lib/
├── infrastructure/
│   └── platform/
│       └── vault_state_sync.dart    # 状态同步

macos/Runner/
├── VaultStateManager.swift          # macOS 状态管理器
└── VaultSyncPlugin.swift            # macOS 插件

windows/runner/
├── vault_state_manager.cpp          # Windows 状态管理器
└── vault_sync_plugin.cpp            # Windows 插件
```

**关键代码（Flutter）**:
```dart
class VaultStateSync {
  static const _channel = MethodChannel('com.hedge.vault_sync');
  static const _eventChannel = EventChannel('com.hedge.vault_sync/events');

  Stream<Map<String, dynamic>>? _stateStream;

  // 监听状态变更
  Stream<Map<String, dynamic>> watchStateChanges() {
    _stateStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
    return _stateStream!;
  }

  // 更新状态
  Future<void> updateState(Map<String, dynamic> state) async {
    await _channel.invokeMethod('updateState', state);
  }
}
```

**关键代码（macOS Swift）**:
```swift
class VaultStateManager {
    static let shared = VaultStateManager()
    private var state: [String: Any] = [:]
    private var eventSinks: [FlutterEventSink] = []

    func updateState(_ newState: [String: Any]) {
        state = newState
        // 广播到所有监听者
        for sink in eventSinks {
            sink(newState)
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

---

### 任务 3.6：快速复制功能（1 天）

**开发内容**:
- [ ] 实现复制用户名
- [ ] 实现复制密码
- [ ] 实现复制网址
- [ ] 实现复制成功提示
- [ ] 实现 60 秒后清空剪贴板
- [ ] 实现键盘快捷键复制

**复用现有代码**:
- 复用 `VaultProvider` 的 `copyPassword()` 方法
- 复用剪贴板清理逻辑

---

## 阶段 4：测试和优化（2-3 天）

### 任务 4.1：功能测试（1 天）

**测试内容**:
- [ ] 系统托盘图标显示/隐藏
- [ ] 面板打开/关闭
- [ ] 搜索功能
- [ ] 列表滚动
- [ ] 详情显示
- [ ] 快速复制
- [ ] 键盘导航
- [ ] 状态同步（主窗口 ↔ 面板）
- [ ] 解锁状态同步
- [ ] 多显示器支持
- [ ] 边界情况（屏幕边缘）

**测试平台**:
- macOS 12.0+ (M1/Intel)
- Windows 10+
- Linux Ubuntu 20.04+

---

### 任务 4.2：性能优化（0.5-1 天）

**优化内容**:
- [ ] 优化冷启动时间（目标 < 500ms）
- [ ] 优化热启动时间（目标 < 200ms）
- [ ] 优化内存占用（目标 < 100MB）
- [ ] 优化搜索响应时间（目标 < 100ms）
- [ ] 优化列表滚动帧率（目标 60fps）

**优化策略**:
- 延迟初始化（首次点击图标时才创建窗口）
- 列表懒加载（ListView.builder）
- 搜索防抖（300ms）
- 状态同步节流

---

### 任务 4.3：用户体验优化（0.5-1 天）

**优化内容**:
- [ ] 添加首次使用引导
- [ ] 优化动画效果（面板打开/关闭）
- [ ] 优化焦点管理
- [ ] 优化空状态提示
- [ ] 优化错误提示

---

## 风险管理

### 高风险项

1. **多窗口状态同步复杂度高**
   - 风险：MethodChannel + EventChannel 方案可能过于复杂
   - 缓解：提前验证方案，准备降级到 Overlay 方案
   - 应急：如果方案 A 无法实现，降级到方案 B

2. **系统托盘插件不稳定**
   - 风险：第三方插件可能存在 bug 或兼容性问题
   - 缓解：提前充分测试，准备自行开发 Platform Channel
   - 应急：如果插件不可用，自行开发 Native 代码

3. **性能指标无法达成**
   - 风险：冷启动时间可能超过 500ms
   - 缓解：实现预加载机制，应用启动时初始化面板
   - 应急：调整性能指标，或优化 Flutter 引擎启动

### 中风险项

1. **独立窗口方案内存占用过高**
   - 风险：独立 Flutter 实例可能占用 100MB+ 内存
   - 缓解：实现延迟初始化，面板关闭后释放资源
   - 应急：降级到 Overlay 方案

2. **面板位置计算错误**
   - 风险：多显示器或屏幕边缘场景下位置计算错误
   - 缓解：充分测试各种场景，实现智能位置调整
   - 应急：提供手动调整面板位置的选项

---

## 里程碑

| 里程碑 | 日期 | 交付物 |
|--------|------|--------|
| M1: 技术预研完成 | Day 5 | 插件选型报告、技术验证报告、性能基准报告 |
| M2: UI 设计完成 | Day 8 | Figma 设计稿、设计规范文档 |
| M3: 核心功能完成 | Day 15 | 系统托盘、独立窗口、面板 UI、键盘导航 |
| M4: 状态同步完成 | Day 18 | 多窗口状态同步、解锁状态同步 |
| M5: 测试优化完成 | Day 21 | 功能测试报告、性能优化报告 |
| M6: 发布准备完成 | Day 23 | 发布候选版本 (RC) |

---

## 资源需求

### 人力资源
- **开发工程师**: 1 人（全职）
- **UI 设计师**: 0.5 人（兼职，仅设计阶段）
- **测试工程师**: 0.5 人（兼职，测试阶段）

### 技术资源
- macOS 开发环境（M1/Intel）
- Windows 开发环境
- Linux 开发环境（虚拟机或实体机）
- 多显示器测试环境

---

## 成功标准

### 功能完整性
- ✅ 所有 MVP 功能已实现
- ✅ 通过功能测试（无阻塞性 bug）
- ✅ 支持 macOS/Windows/Linux 三平台

### 性能指标
- ✅ 热启动 < 200ms
- ✅ 冷启动 < 500ms
- ✅ 内存占用 < 100MB
- ✅ 搜索响应 < 100ms
- ✅ 列表滚动 60fps

### 用户体验
- ✅ 键盘导航流畅
- ✅ 状态同步实时
- ✅ 无明显卡顿或延迟
- ✅ 错误提示清晰

---

## 下一步行动

### 立即执行
1. ✅ 创建项目分支：`feature/desktop-quick-access`
2. ✅ 开始技术预研：任务 1.1（系统托盘插件评估）
3. ✅ 准备测试环境：macOS/Windows/Linux

### 本周目标
- 完成技术预研（任务 1.1-1.4）
- 输出技术方案报告
- 确定最终技术栈

---

**文档版本**: 1.0
**最后更新**: 2026-03-01
**负责人**: 开发团队
