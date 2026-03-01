import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
      ),
      body: ListView(
        children: [
          // 当前同步状态
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前同步方式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSyncModeDisplayName(currentMode),
                    style: const TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  if (currentMode == SyncMode.webdav && vaultState.webdavConfig != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '服务器: ${vaultState.webdavConfig!.serverUrl}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '选择同步方式',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),

          // 本地存储
          _SyncModeCard(
            title: '仅本地存储',
            subtitle: '数据仅保存在本设备',
            icon: Icons.phone_android,
            mode: SyncMode.local,
            currentMode: currentMode,
            isAvailable: true,
            onTap: () async {
              await ref.read(vaultProvider.notifier).setSyncMode(SyncMode.local);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已切换到本地存储模式')),
                );
              }
            },
          ),

          // iCloud Drive (仅 iOS/macOS)
          if (Platform.isIOS || Platform.isMacOS)
            _SyncModeCard(
              title: 'iCloud Drive',
              subtitle: '自动同步到 iPhone、iPad、Mac',
              icon: Icons.cloud,
              mode: SyncMode.icloud,
              currentMode: currentMode,
              isAvailable: true,
              badge: '需要付费开发者账号',
              onTap: () async {
                final available = await VaultNotifier.isICloudDriveAvailable();
                if (!available) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('iCloud Drive 不可用'),
                        content: const Text(
                          'iCloud Drive 功能需要：\n\n'
                          '1. 付费的 Apple Developer Program (\$99/年)\n'
                          '2. 在 Xcode 中配置 iCloud capability\n\n'
                          '建议使用 WebDAV 作为替代方案。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('知道了'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                await ref.read(vaultProvider.notifier).setSyncMode(SyncMode.icloud);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已切换到 iCloud Drive 模式')),
                  );
                }
              },
            ),

          // WebDAV
          _SyncModeCard(
            title: 'WebDAV 同步',
            subtitle: '使用您的私有云服务器（推荐）',
            icon: Icons.cloud_sync,
            mode: SyncMode.webdav,
            currentMode: currentMode,
            isAvailable: true,
            badge: '跨平台',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WebDAVSettingsPage(),
                ),
              );
            },
          ),

          // 说明
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '同步方式说明',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('• 本地存储：数据仅保存在本设备，最安全但无法跨设备同步'),
                    SizedBox(height: 8),
                    Text('• iCloud Drive：Apple 生态自动同步，需要付费开发者账号'),
                    SizedBox(height: 8),
                    Text('• WebDAV：使用自己的服务器，完全掌控数据，支持所有平台'),
                    SizedBox(height: 12),
                    Text(
                      '注意：同一时间只能使用一种同步方式',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSyncModeDisplayName(SyncMode mode) {
    switch (mode) {
      case SyncMode.local:
        return '仅本地存储';
      case SyncMode.icloud:
        return 'iCloud Drive';
      case SyncMode.webdav:
        return 'WebDAV 同步';
    }
  }
}

class _SyncModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final SyncMode mode;
  final SyncMode currentMode;
  final bool isAvailable;
  final String? badge;
  final VoidCallback onTap;

  const _SyncModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.isAvailable,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : null,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue)
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
