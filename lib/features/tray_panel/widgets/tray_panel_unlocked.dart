import 'dart:async';
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
  String? _hoveredItemId;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _hoverTimer?.cancel();
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

    if (items.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPasswordItem(context, l10n, isDark, item);
      },
    );
  }

  /// 构建密码项
  Widget _buildPasswordItem(BuildContext context, AppLocalizations l10n, bool isDark, item) {
    final title = item.title ?? '';
    final subtitle = item.username ?? item.url ?? '';
    final displayChar = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final itemId = item.id ?? '';
    final isHovered = _hoveredItemId == itemId;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredItemId = itemId);

        // 悬浮 2 秒后显示详情
        _hoverTimer?.cancel();
        _hoverTimer = Timer(const Duration(seconds: 2), () {
          if (_hoveredItemId == itemId) {
            // TODO: 显示详情面板
            debugPrint('显示详情: $title');
          }
        });
      },
      onExit: (_) {
        setState(() => _hoveredItemId = null);
        _hoverTimer?.cancel();
      },
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          // TODO: 复制密码到剪贴板
          debugPrint('点击: $title');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered
                ? (isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E5EA))
                : (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white),
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
              const SizedBox(width: 10),

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
