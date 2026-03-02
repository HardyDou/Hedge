import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import '../services/panel_window_service.dart';
import '../services/tray_service.dart';
import 'tray_panel_locked.dart';
import 'tray_panel_unlocked.dart';

/// 托盘快捷面板 UI 组件
class TrayPanel extends ConsumerWidget {
  final PanelWindowService panelWindowService;
  final TrayService trayService;

  const TrayPanel({
    super.key,
    required this.panelWindowService,
    required this.trayService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    // 根据认证状态显示不同的界面
    if (vaultState.isAuthenticated) {
      return TrayPanelUnlocked(
        panelWindowService: panelWindowService,
        trayService: trayService,
      );
    } else {
      return TrayPanelLocked(
        panelWindowService: panelWindowService,
        trayService: trayService,
      );
    }
  }
}
