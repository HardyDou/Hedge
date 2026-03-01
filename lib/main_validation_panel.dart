import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';
import 'tech_validation_panel.dart';

/// 独立窗口 Panel 验证入口
/// 运行命令: fvm flutter run -d macos -t lib/main_validation_panel.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: CupertinoColors.systemBackground,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const TechValidationPanelApp());
}
