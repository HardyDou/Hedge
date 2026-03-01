import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../models/panel_state.dart';

/// Panel 窗口管理服务
/// 负责管理 Panel 窗口的显示、隐藏、位置等
class PanelWindowService extends ChangeNotifier {
  PanelState _state = const PanelState();

  PanelState get state => _state;

  /// Panel 窗口尺寸
  static const double panelWidth = 240.0;
  static const double panelHeight = 320.0;

  /// 主窗口默认尺寸
  static const double mainWindowWidth = 800.0;
  static const double mainWindowHeight = 600.0;

  /// 显示 Panel 窗口
  Future<void> showPanel({required double x, required double y}) async {
    debugPrint('显示 Panel 窗口: ($x, $y)');

    // 切换到 Panel 模式
    _state = _state.copyWith(isPanelMode: true);
    notifyListeners();

    // 配置窗口为 Panel 样式
    await windowManager.setSize(Size(panelWidth, panelHeight));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setMovable(false);
    await windowManager.setTitle('');

    // 设置无边框样式
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    // 设置位置并显示
    await windowManager.setPosition(Offset(x, y));
    await windowManager.show();
    await windowManager.focus();

    _state = _state.copyWith(isVisible: true, isActive: true);
    notifyListeners();

    debugPrint('Panel 窗口已显示');
  }

  /// 隐藏 Panel 窗口
  Future<void> hidePanel() async {
    debugPrint('隐藏 Panel 窗口');

    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);

    _state = _state.copyWith(isVisible: false, isActive: false);
    notifyListeners();
  }

  /// 切换 Panel 显示/隐藏
  Future<void> togglePanel({required double x, required double y}) async {
    if (_state.isPanelMode && _state.isVisible) {
      await hidePanel();
    } else {
      await showPanel(x: x, y: y);
    }
  }

  /// 显示主窗口
  Future<void> showMainWindow() async {
    debugPrint('显示主窗口');

    // 切换回主窗口模式
    _state = const PanelState();
    notifyListeners();

    // 恢复主窗口样式
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.setMovable(true);
    await windowManager.setSize(Size(mainWindowWidth, mainWindowHeight));
    await windowManager.center();
    await windowManager.setTitle('Hedge');
    await windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();

    debugPrint('主窗口已显示');
  }

  /// Panel 失焦处理
  Future<void> onPanelBlur() async {
    if (_state.isPanelMode && _state.isVisible) {
      debugPrint('Panel 失焦，自动隐藏');
      await Future.delayed(const Duration(milliseconds: 100));
      await hidePanel();
    }
  }

  /// 窗口关闭处理
  Future<void> onWindowClose() async {
    if (_state.isPanelMode) {
      // Panel 模式下，关闭就是隐藏
      await hidePanel();
    } else {
      // 主窗口模式，关闭进入托盘
      debugPrint('主窗口关闭，进入托盘状态');
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

  /// 计算 Panel 位置
  /// [trayX] 托盘图标 X 坐标
  /// [trayY] 托盘图标 Y 坐标
  /// [trayWidth] 托盘图标宽度
  /// [trayHeight] 托盘图标高度
  static Map<String, double> calculatePanelPosition({
    required double trayX,
    required double trayY,
    required double trayWidth,
    required double trayHeight,
  }) {
    // Panel 居中对齐托盘图标
    double panelX = trayX - panelWidth / 2 + trayWidth / 2;

    // Y 坐标：尝试使用菜单栏高度减去标题栏高度
    // 这是一个近似值，可能需要根据实际情况调整
    double menuBarHeight = 25.0;
    double titleBarHeight = 28.0;
    double panelY = menuBarHeight - titleBarHeight;

    // 边界检查
    if (panelX < 0) panelX = 0;

    return {
      'x': panelX,
      'y': panelY,
    };
  }
}
