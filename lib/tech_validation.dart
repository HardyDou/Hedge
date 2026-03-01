import 'package:flutter/cupertino.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 技术验证：托盘快捷面板核心功能
///
/// 验证内容：
/// 1. 是否可以为 app 添加托盘图标
/// 2. 关闭主窗口是否可以进入托盘状态（不退出应用）
/// 3. 点击托盘是否可以弹出一个 Panel
/// 4. 点击 Panel 是否可以打开主窗口
/// 5. 点击 Panel 的退出是否可以退出应用
class TechValidationApp extends StatefulWidget {
  const TechValidationApp({super.key});

  @override
  State<TechValidationApp> createState() => _TechValidationAppState();
}

class _TechValidationAppState extends State<TechValidationApp>
    with TrayListener, WindowListener {
  bool _isPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _initTrayAndWindow();
  }

  Future<void> _initTrayAndWindow() async {
    // 初始化 window_manager
    await windowManager.ensureInitialized();
    trayManager.addListener(this);
    windowManager.addListener(this);

    // 配置主窗口
    await windowManager.setTitle('技术验证 - 主窗口');
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();

    // 初始化托盘图标
    await _initTray();
  }

  Future<void> _initTray() async {
    // 使用 app icon 作为托盘图标（临时）
    // macOS 托盘图标推荐使用 16x16 或 32x32
    await trayManager.setIcon(
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png',
      isTemplate: true, // macOS 风格，自动适配深色/浅色模式
    );

    // 设置托盘提示文本
    await trayManager.setToolTip('Hedge 密码管理器');

    // 设置托盘菜单
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_panel',
          label: '显示快捷面板',
        ),
        MenuItem(
          key: 'show_main',
          label: '打开主窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: '退出应用',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    debugPrint('✅ 验证 1: 托盘图标已创建');
  }

  @override
  void onTrayIconMouseDown() {
    debugPrint('✅ 验证 3: 托盘图标被点击');
    _showPanel();
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
    // 验证 2: 关闭主窗口不退出应用，进入托盘状态
    debugPrint('✅ 验证 2: 主窗口关闭，应用进入托盘状态（不退出）');
    await windowManager.hide();
  }

  void _showPanel() {
    setState(() {
      _isPanelVisible = true;
    });
    debugPrint('✅ 验证 3: 快捷面板显示');
  }

  void _hidePanel() {
    setState(() {
      _isPanelVisible = false;
    });
    debugPrint('快捷面板隐藏');
  }

  void _showMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
    debugPrint('✅ 验证 4: 主窗口显示');
  }

  void _exitApp() {
    debugPrint('✅ 验证 5: 退出应用');
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
      home: Stack(
        children: [
          // 主窗口
          CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('技术验证 - 主窗口'),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '托盘快捷面板技术验证',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    _buildValidationItem('1. 托盘图标已创建', true),
                    _buildValidationItem('2. 关闭窗口进入托盘（点击关闭按钮测试）', null),
                    _buildValidationItem('3. 点击托盘弹出面板', _isPanelVisible),
                    _buildValidationItem('4. 从面板打开主窗口', null),
                    _buildValidationItem('5. 从面板退出应用', null),
                    const SizedBox(height: 40),
                    CupertinoButton.filled(
                      onPressed: _showPanel,
                      child: const Text('显示快捷面板'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 快捷面板（模拟）
          if (_isPanelVisible)
            Positioned(
              right: 20,
              top: 100,
              child: _buildPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String text, bool? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == true
                ? CupertinoIcons.check_mark_circled_solid
                : status == false
                    ? CupertinoIcons.xmark_circle_fill
                    : CupertinoIcons.circle,
            color: status == true
                ? CupertinoColors.systemGreen
                : status == false
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '快捷面板',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _hidePanel,
                  child: const Icon(CupertinoIcons.xmark),
                ),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '这是快捷面板',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '✅ 验证 3: 面板可以弹出',
                    style: TextStyle(color: CupertinoColors.systemGreen),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      _hidePanel();
                      _showMainWindow();
                    },
                    child: const Text('打开主窗口'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.systemRed,
                    onPressed: _exitApp,
                    child: const Text('退出应用'),
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
