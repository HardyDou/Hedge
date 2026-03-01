import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';
import 'tech_validation.dart';

/// 技术验证入口
/// 运行命令: fvm flutter run -d macos -t lib/main_validation.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 window_manager
  await windowManager.ensureInitialized();

  // 配置窗口选项 - 关键：阻止默认关闭行为
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: CupertinoColors.systemBackground,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 必须在这里设置 preventClose
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const TechValidationApp());
}
