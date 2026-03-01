import 'package:flutter/cupertino.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 技术验证：托盘快捷面板核心功能
///
/// 验证内容：
/// 1. 是否可以为 app 添加托盘图标
/// 2. 关闭主窗口是否可以进入托盘状态（不退出应用）
/// 3. 点击托盘是否可以弹出一个独立的 Panel 窗口
/// 4. Panel 窗口是否可以从托盘图标位置弹出
/// 5. 点击 Panel 是否可以打开主窗口
/// 6. 点击 Panel 的退出是否可以退出应用
class TechValidationApp extends StatefulWidget {
  const TechValidationApp({super.key});

  @override
  State<TechValidationApp> createState() => _TechValidationAppState();
}

class _TechValidationAppState extends State<TechValidationApp>
    with TrayListener, WindowListener {

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
    await trayManager.setIcon(
      'assets/icons/tray_icon.png',
      isTemplate: true,
    );

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

  Future<void> _showPanel() async {
    // TODO: 这里需要创建独立的 Panel 窗口
    // 当前验证阶段，先打印日志
    debugPrint('✅ 验证 3: 准备显示快捷面板');

    // 获取托盘图标位置
    final trayBounds = await trayManager.getBounds();
    debugPrint('托盘图标位置: ${trayBounds?.left}, ${trayBounds?.top}');
    debugPrint('托盘图标尺寸: ${trayBounds?.width}, ${trayBounds?.height}');

    // 获取屏幕尺寸
    final screenSize = await windowManager.getSize();
    debugPrint('屏幕尺寸: ${screenSize.width}, ${screenSize.height}');

    // 计算 Panel 窗口位置
    if (trayBounds != null) {
      const panelWidth = 350.0;
      const panelHeight = 500.0;

      // 从托盘图标下方弹出
      double panelX = trayBounds.left - panelWidth / 2 + trayBounds.width / 2;
      double panelY = trayBounds.top + trayBounds.height + 5;

      debugPrint('✅ 验证 4: Panel 窗口位置计算完成: ($panelX, $panelY)');
      debugPrint('Panel 窗口尺寸: ${panelWidth}x$panelHeight');
    }
  }

  void _showMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
    debugPrint('✅ 验证 5: 主窗口显示');
  }

  void _exitApp() {
    debugPrint('✅ 验证 6: 退出应用');
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
      home: CupertinoPageScaffold(
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
                _buildValidationItem('3. 点击托盘触发事件', null),
                _buildValidationItem('4. 计算 Panel 窗口位置', null),
                _buildValidationItem('5. 从托盘菜单打开主窗口', null),
                _buildValidationItem('6. 从托盘菜单退出应用', null),
                const SizedBox(height: 40),
                const Text(
                  '操作说明：',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('1. 点击菜单栏的托盘图标（左键）'),
                const Text('2. 右键点击托盘图标查看菜单'),
                const Text('3. 关闭主窗口测试托盘状态'),
                const Text('4. 查看控制台输出验证结果'),
              ],
            ),
          ),
        ),
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
}
