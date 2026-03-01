import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'panel_window_service.dart';

/// 托盘管理服务
/// 负责托盘图标的创建、菜单管理、事件处理
class TrayService with TrayListener {
  final PanelWindowService panelWindowService;

  TrayService({required this.panelWindowService});

  /// 初始化托盘
  Future<void> initialize() async {
    debugPrint('初始化托盘服务');

    // 添加托盘监听器
    trayManager.addListener(this);

    // 设置托盘图标
    await trayManager.setIcon(
      'assets/icons/tray_icon.png',
      isTemplate: true,
    );

    // 设置托盘提示文本
    await trayManager.setToolTip('Hedge 密码管理器');

    // 设置托盘菜单
    await _updateContextMenu();

    debugPrint('托盘服务初始化完成');
  }

  /// 更新托盘菜单
  Future<void> _updateContextMenu() async {
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
  }

  @override
  void onTrayIconMouseDown() {
    debugPrint('托盘图标被点击（左键）');
    _togglePanel();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('托盘图标被点击（右键）');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('托盘菜单项被点击: ${menuItem.key}');

    switch (menuItem.key) {
      case 'show_panel':
        _togglePanel();
        break;
      case 'show_main':
        _showMainWindow();
        break;
      case 'exit':
        _exitApp();
        break;
    }
  }

  /// 切换 Panel 显示/隐藏
  Future<void> _togglePanel() async {
    try {
      // 获取托盘图标位置
      final trayBounds = await trayManager.getBounds();
      if (trayBounds == null) {
        debugPrint('无法获取托盘位置');
        return;
      }

      debugPrint('托盘位置: (${trayBounds.left}, ${trayBounds.top})');
      debugPrint('托盘尺寸: ${trayBounds.width} x ${trayBounds.height}');

      // 计算 Panel 位置
      final position = PanelWindowService.calculatePanelPosition(
        trayX: trayBounds.left,
        trayY: trayBounds.top,
        trayWidth: trayBounds.width,
        trayHeight: trayBounds.height,
      );

      // 切换 Panel
      await panelWindowService.togglePanel(
        x: position['x']!,
        y: position['y']!,
      );
    } catch (e) {
      debugPrint('切换 Panel 失败: $e');
    }
  }

  /// 显示主窗口
  Future<void> _showMainWindow() async {
    try {
      await panelWindowService.showMainWindow();
    } catch (e) {
      debugPrint('显示主窗口失败: $e');
    }
  }

  /// 退出应用
  void exitApp() {
    debugPrint('退出应用');
    windowManager.destroy();
  }

  /// 退出应用（私有方法，供内部使用）
  void _exitApp() {
    exitApp();
  }

  /// 清理资源
  void dispose() {
    trayManager.removeListener(this);
  }
}
