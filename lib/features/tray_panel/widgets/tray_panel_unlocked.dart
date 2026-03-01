import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import '../services/panel_window_service.dart';
import '../services/tray_service.dart';

/// 托盘面板 - 已解锁状态
class TrayPanelUnlocked extends ConsumerStatefulWidget {
  final PanelWindowService panelWindowService;
  final TrayService trayService;

  const TrayPanelUnlocked({
    super.key,
    required this.panelWindowService,
    required this.trayService,
  });

  @override
  ConsumerState<TrayPanelUnlocked> createState() => _TrayPanelUnlockedState();
}

class _TrayPanelUnlockedState extends ConsumerState<TrayPanelUnlocked> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final vaultState = ref.watch(vaultProvider);

    return Column(
      children: [
        // 标题栏（带右侧按钮）
        _buildHeader(context, l10n, isDark),

        // 搜索框
        _buildSearchBar(context, l10n, isDark),

        // 内容区域
        Expanded(
          child: _buildContent(context, l10n, isDark, vaultState),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧标题
          Icon(
            CupertinoIcons.lock_shield_fill,
            size: 16,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.quickAccess,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),

          const Spacer(),

          // 右侧按钮组
          _buildHeaderIconButton(
            context: context,
            icon: CupertinoIcons.square_arrow_up_on_square,
            tooltip: l10n.openMainWindow,
            isDark: isDark,
            onPressed: () async {
              await widget.panelWindowService.showMainWindow();
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            context: context,
            icon: CupertinoIcons.gear,
            tooltip: l10n.quickSettings,
            isDark: isDark,
            onPressed: () {
              // TODO: 打开快速设置
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            context: context,
            icon: CupertinoIcons.lock,
            tooltip: l10n.lockNow,
            isDark: isDark,
            onPressed: () {
              ref.read(vaultProvider.notifier).lock();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      height: 36,
      margin: const EdgeInsets.all(12),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: l10n.quickSearch,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
        placeholderStyle: TextStyle(
          fontSize: 13,
          color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
        ),
        backgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        onChanged: (value) {
          ref.read(vaultProvider.notifier).searchItems(value);
        },
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, AppLocalizations l10n, bool isDark, VaultState vaultState) {
    final items = vaultState.filteredVaultItems ?? [];
    final recentItems = items.take(5).toList(); // 显示最近 5 个

    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lock_circle,
              size: 48,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noRecentPasswords,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.recentlyUsed,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
          ),
        ),

        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recentItems.length,
            itemBuilder: (context, index) {
              final item = recentItems[index];
              return _buildPasswordItem(context, l10n, isDark, item);
            },
          ),
        ),
      ],
    );
  }

  /// 构建密码项
  Widget _buildPasswordItem(BuildContext context, AppLocalizations l10n, bool isDark, item) {
    final title = item.title ?? '';
    final subtitle = item.username ?? item.url ?? '';
    final displayChar = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          // TODO: 复制密码到剪贴板
          // 显示"已复制"提示
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF38383A)
                  : const Color(0xFFC6C6C8),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getColorForChar(displayChar).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    displayChar,
                    style: TextStyle(
                      color: _getColorForChar(displayChar),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题栏图标按钮
  Widget _buildHeaderIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    );
  }

  /// 获取字符对应的颜色
  Color _getColorForChar(String char) {
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFFFF3B30),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF2D55),
      const Color(0xFF5856D6),
      const Color(0xFF00C7BE),
      const Color(0xFFFFCC00),
    ];
    final index = char.toUpperCase().codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
