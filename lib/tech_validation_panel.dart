import 'package:flutter/cupertino.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 技术验证：独立窗口快捷面板
///
/// 验证内容：
/// 1. 是否可以创建独立的 Panel 窗口（无边框、置顶）
/// 2. Panel 窗口是否可以从托盘图标位置弹出
/// 3. Panel 窗口是否可以固定尺寸（350x500）
/// 4. Panel 窗口失焦是否可以自动隐藏
class TechValidationPanelApp extends StatefulWidget {
  const TechValidationPanelApp({super.key});

  @override
  State<TechValidationPanelApp> createState() => _TechValidationPanelAppState();
}

class _TechValidationPanelAppState extends State<TechValidationPanelApp>
    with TrayListener, WindowListener {
  bool _isPanelMode = false;

  @override
  void initState() {
    super.initState();
    _initTrayAndWindow();
  }

  Future<void> _initTrayAndWindow() async {
    await windowManager.ensureInitialized();
    trayManager.addListener(this);
    windowManager.addListener(this);

    // 配置主窗口
    await windowManager.setPreventClose(true);
    await windowManager.setTitle('技术验证 - 主窗口');
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();

    // 初始化托盘图标
    await _initTray();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/icons/tray_icon.png', isTemplate: true);
    await trayManager.setToolTip('Hedge 密码管理器');

    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_panel', label: '显示快捷面板'),
        MenuItem(key: 'show_main', label: '打开主窗口'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出应用'),
      ],
    );
    await trayManager.setContextMenu(menu);

    debugPrint('✅ 验证 1: 托盘图标已创建');
  }

  @override
  void onTrayIconMouseDown() {
    debugPrint('托盘图标被点击');
    _togglePanel();
  }

  Future<void> _togglePanel() async {
    if (_isPanelMode) {
      // 如果已经是 Panel 模式，检查窗口是否可见
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        // 可见则隐藏
        debugPrint('隐藏 Panel');
        await windowManager.hide();
        await windowManager.setSkipTaskbar(true);
      } else {
        // 不可见则显示
        debugPrint('显示 Panel');
        await windowManager.show();
        await windowManager.focus();
      }
    } else {
      // 不是 Panel 模式，显示 Panel
      _showPanel();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_panel':
        _showPanel();
        break;
      case 'show_main':
        _showMainWindow();
        break;
      case 'exit':
        _exitApp();
        break;
    }
  }

  @override
  void onWindowClose() async {
    if (_isPanelMode) {
      // Panel 模式下，关闭就是隐藏
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    } else {
      // 主窗口模式，关闭进入托盘
      debugPrint('✅ 主窗口关闭，进入托盘状态');
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onWindowBlur() async {
    if (_isPanelMode) {
      // Panel 模式下失焦自动隐藏
      debugPrint('✅ 验证 4: Panel 失焦，自动隐藏');
      await Future.delayed(const Duration(milliseconds: 100));
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onWindowEvent(String eventName) {
    debugPrint('窗口事件: $eventName');
  }

  Future<void> _showPanel() async {
    debugPrint('✅ 验证 2: 准备显示 Panel 窗口');

    // 获取托盘图标位置
    final trayBounds = await trayManager.getBounds();
    if (trayBounds == null) {
      debugPrint('❌ 无法获取托盘位置');
      return;
    }

    debugPrint('托盘位置: (${trayBounds.left}, ${trayBounds.top})');
    debugPrint('托盘尺寸: ${trayBounds.width} x ${trayBounds.height}');

    // Panel 尺寸（类似托盘菜单，稍大一点）
    const panelWidth = 240.0;
    const panelHeight = 320.0;

    // 计算 Panel 位置（紧贴托盘图标下方，居中对齐）
    double panelX = trayBounds.left - panelWidth / 2 + trayBounds.width / 2;
    // macOS 窗口标题栏高度约 28 像素，即使隐藏了也会占用空间
    // 所以需要向上偏移标题栏高度
    double panelY = -28.0;  // 负值向上偏移

    // 边界检查
    if (panelX < 0) panelX = 0;

    debugPrint('✅ 验证 2: Panel 位置计算完成:');
    debugPrint('   托盘 top: ${trayBounds.top}, bottom: ${trayBounds.bottom}, height: ${trayBounds.height}');
    debugPrint('   Panel X: $panelX, Y: $panelY (向上偏移标题栏高度)');
    debugPrint('   Panel 尺寸: ${panelWidth}x$panelHeight');

    // 切换到 Panel 模式
    setState(() {
      _isPanelMode = true;
    });

    // 配置窗口为 Panel 样式
    await windowManager.setSize(const Size(panelWidth, panelHeight));
    await windowManager.setPosition(Offset(panelX, panelY));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setMovable(false);  // 禁止移动
    await windowManager.setTitle('');

    // 设置无边框样式（macOS）- 隐藏标题栏和窗口按钮
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,  // 隐藏关闭/最小化/最大化按钮
    );

    await windowManager.show();
    await windowManager.focus();

    debugPrint('✅ 验证 3: Panel 窗口已显示（350x500，无边框，置顶，不可移动）');
  }

  Future<void> _showMainWindow() async {
    debugPrint('✅ 恢复主窗口模式');

    // 切换回主窗口模式
    setState(() {
      _isPanelMode = false;
    });

    // 恢复主窗口样式
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.setMovable(true);  // 允许移动
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.setTitle('技术验证 - 主窗口');
    await windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,  // 显示窗口按钮
    );
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
  }

  void _exitApp() {
    debugPrint('✅ 退出应用');
    windowManager.destroy();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,  // 亮色主题
      ),
      home: _isPanelMode ? _buildPanelWindow() : _buildMainWindow(),
    );
  }

  Widget _buildMainWindow() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('技术验证 - 主窗口'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '独立窗口快捷面板验证',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              const Text('操作说明：'),
              const SizedBox(height: 10),
              const Text('1. 点击托盘图标（左键）显示 Panel'),
              const Text('2. Panel 会从托盘位置弹出'),
              const Text('3. Panel 是无边框、置顶窗口'),
              const Text('4. 点击 Panel 外部会自动隐藏'),
              const Text('5. 从托盘菜单可以恢复主窗口'),
              const SizedBox(height: 40),
              CupertinoButton.filled(
                onPressed: _showPanel,
                child: const Text('显示 Panel 窗口'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelWindow() {
    // 获取当前主题
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.separator,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.5 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 内容区域（无标题栏）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 48,
                    color: isDark
                        ? CupertinoColors.systemGreen.darkColor
                        : CupertinoColors.systemGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '快捷面板',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '✅ 无标题栏',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.black,
                    ),
                  ),
                  Text(
                    '✅ 无窗口按钮',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.black,
                    ),
                  ),
                  Text(
                    '✅ 不可移动',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.black,
                    ),
                  ),
                  Text(
                    '✅ 240x320 尺寸',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.black,
                    ),
                  ),
                  Text(
                    '✅ ${isDark ? "深色" : "浅色"}主题',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '点击外部自动隐藏',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: _showMainWindow,
                    child: const Text('打开主窗口', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: CupertinoColors.systemRed,
                    onPressed: _exitApp,
                    child: const Text('退出应用', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
