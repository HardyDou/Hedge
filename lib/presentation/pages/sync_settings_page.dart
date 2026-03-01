import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/domain/models/sync_config.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/presentation/pages/webdav_settings_page.dart';
import 'dart:io';

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);
    final currentMode = vaultState.syncMode;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('同步'),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 本地存储
            _buildSyncModeCard(
              context: context,
              ref: ref,
              title: '仅本地存储',
              subtitle: '数据仅保存在本设备',
              icon: CupertinoIcons.device_phone_portrait,
              mode: SyncMode.local,
              currentMode: currentMode,
              isDark: isDark,
            ),

            const SizedBox(height: 12),

            // iCloud Drive (仅 iOS/macOS)
            if (Platform.isIOS || Platform.isMacOS)
              _buildSyncModeCard(
                context: context,
                ref: ref,
                title: 'iCloud Drive',
                subtitle: '自动同步到 iPhone、iPad、Mac',
                icon: CupertinoIcons.cloud,
                badge: '需付费账号',
                mode: SyncMode.icloud,
                currentMode: currentMode,
                isDark: isDark,
              ),

            if (Platform.isIOS || Platform.isMacOS)
              const SizedBox(height: 12),

            // WebDAV
            _buildSyncModeCard(
              context: context,
              ref: ref,
              title: 'WebDAV 同步',
              subtitle: currentMode == SyncMode.webdav && vaultState.webdavConfig != null
                  ? vaultState.webdavConfig!.serverUrl
                  : '使用您的私有云服务器',
              icon: CupertinoIcons.cloud_upload,
              badge: '跨平台',
              mode: SyncMode.webdav,
              currentMode: currentMode,
              isDark: isDark,
              onTapWebDAV: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const WebDAVSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
    required SyncMode mode,
    required SyncMode currentMode,
    required bool isDark,
    VoidCallback? onTapWebDAV,
  }) {
    final isSelected = mode == currentMode;

    return GestureDetector(
      onTap: () async {
        if (mode == SyncMode.webdav) {
          onTapWebDAV?.call();
          return;
        }

        if (mode == SyncMode.icloud) {
          final available = await VaultNotifier.isICloudDriveAvailable();
          if (!available) {
            if (context.mounted) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('iCloud Drive 不可用'),
                  content: const Text(
                    'iCloud Drive 功能需要：\n\n'
                    '1. 付费的 Apple Developer Program (\$99/年)\n'
                    '2. 在 Xcode 中配置 iCloud capability\n\n'
                    '建议使用 WebDAV 作为替代方案。',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }

        await ref.read(vaultProvider.notifier).setSyncMode(mode);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue
                : (isDark ? const Color(0xFF3C3C3E) : CupertinoColors.systemGrey5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : (isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : (isDark ? CupertinoColors.white : CupertinoColors.black),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.systemOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? CupertinoColors.white.withOpacity(0.6)
                          : CupertinoColors.black.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.activeBlue,
                size: 24,
              )
            else
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.3)
                    : CupertinoColors.black.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}
