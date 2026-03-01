import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hedge/main.dart' as app;
import 'package:hedge/features/tray_panel/tray_panel.dart';

/// 带托盘功能的主入口
/// 用于 macOS 桌面版本
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 配置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: CupertinoColors.systemBackground,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 运行应用（带托盘功能）
  runApp(const TrayEnabledApp());
}

/// 带托盘功能的应用包装器
class TrayEnabledApp extends StatefulWidget {
  const TrayEnabledApp({super.key});

  @override
  State<TrayEnabledApp> createState() => _TrayEnabledAppState();
}

class _TrayEnabledAppState extends State<TrayEnabledApp> with WindowListener {
  late PanelWindowService _panelWindowService;
  late TrayService _trayService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTray();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _trayService.dispose();
    super.dispose();
  }

  Future<void> _initializeTray() async {
    try {
      // 初始化服务
      _panelWindowService = PanelWindowService();
      _trayService = TrayService(panelWindowService: _panelWindowService);

      // 初始化托盘
      await _trayService.initialize();

      // 设置窗口关闭时不退出
      await windowManager.setPreventClose(true);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('托盘功能初始化完成');
    } catch (e) {
      debugPrint('托盘功能初始化失败: $e');
    }
  }

  @override
  void onWindowClose() async {
    debugPrint('窗口关闭事件');
    await _panelWindowService.onWindowClose();
  }

  @override
  void onWindowBlur() async {
    await _panelWindowService.onPanelBlur();
  }

  @override
  void onWindowEvent(String eventName) {
    debugPrint('窗口事件: $eventName');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    // 根据 Panel 状态显示不同的 UI
    return ListenableBuilder(
      listenable: _panelWindowService,
      builder: (context, child) {
        if (_panelWindowService.state.isPanelMode) {
          // Panel 模式：显示快捷面板
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: const CupertinoThemeData(
              brightness: Brightness.light,
            ),
            home: TrayPanel(
              panelWindowService: _panelWindowService,
              trayService: _trayService,
            ),
          );
        } else {
          // 主窗口模式：显示主应用
          return const app.NotePasswordApp();
        }
      },
    );
  }
}
