import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/presentation/providers/vault_provider.dart';
import 'package:note_password/src/dart/vault.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:note_password/presentation/pages/desktop/detail_panel.dart';
import 'package:note_password/presentation/pages/desktop/settings_panel.dart';
import 'package:note_password/presentation/pages/desktop/add_item_panel.dart';
import 'package:note_password/presentation/pages/desktop/edit_panel.dart';

class DesktopHomePage extends ConsumerStatefulWidget {
  const DesktopHomePage({super.key});

  @override
  ConsumerState<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _menuChannel = const MethodChannel('app.menu');
  String _searchQuery = "";
  VaultItem? _selectedItem;
  bool _showSettings = false;
  bool _showAddItem = false;
  VaultItem? _editingItem;
  double _sidebarWidth = 280;
  static const double _minSidebarWidth = 200;
  static const double _maxSidebarWidth = 500;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      // Don't clear search on blur - user may want to keep search while browsing
      // The search will only be cleared when user explicitly clears it
    });
    _setupMenuChannel();
  }

  void _setupMenuChannel() {
    _menuChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openSettings':
          setState(() => _showSettings = true);
          break;
        case 'showSettings':
          setState(() => _showSettings = true);
          break;
        case 'newEntry':
          setState(() => _showAddItem = true);
          break;
        case 'lockVault':
          ref.read(vaultProvider.notifier).lock();
          break;
        case 'showAbout':
          _showAboutDialog();
          break;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final items = vaultState.vault?.items.where((item) {
          final query = _searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(query) ||
              (item.username?.toLowerCase().contains(query) ?? false) ||
              (item.notes?.toLowerCase().contains(query) ?? false);
        }).toList() ??
        [];

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          _buildNavBar(isDark, l10n),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: _sidebarWidth,
                  child: _buildLeftPanel(items, isDark, l10n, vaultState),
                ),
                _buildDragHandle(isDark),
                Expanded(
                  child: _buildRightPanel(isDark, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isMac = Platform.isMacOS;
      final isControlPressed = isMac
          ? HardwareKeyboard.instance.isMetaPressed
          : HardwareKeyboard.instance.isControlPressed;
      
      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      
      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.comma) {
        final brightness = CupertinoTheme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        _showSettingsDialog(context, isDark);
      }
    }
  }

  Widget _buildRightPanel(bool isDark, AppLocalizations l10n) {
    if (_showAddItem) {
      return AddItemPanel(
        onClose: () => setState(() => _showAddItem = false),
        onSave: (item) {
          setState(() {
            _showAddItem = false;
            _selectedItem = item;
          });
        },
      );
    }

    if (_editingItem != null) {
      return EditPanel(
        item: _editingItem!,
        onClose: () => setState(() => _editingItem = null),
        onSave: (item) {
          setState(() {
            _editingItem = null;
            _selectedItem = item;
          });
        },
      );
    }

    if (_selectedItem != null) {
      return DetailPanel(
        key: ValueKey(_selectedItem!.id),
        item: _selectedItem!,
        onEdit: (item) => setState(() => _editingItem = item),
        onDelete: () => setState(() => _selectedItem = null),
      );
    }

    if (_showSettings) {
      return Container(color: isDark ? CupertinoColors.black : const Color(0xFFF2F2F7));
    }

    return _buildEmptyState(isDark, l10n);
  }

  void _showSettingsDialog(BuildContext context, bool isDark) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Center(
        child: Container(
          width: 450,
          height: 380,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SettingsPanel(
            isModal: true,
            onClose: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _sidebarWidth += details.delta.dx;
            _sidebarWidth = _sidebarWidth.clamp(_minSidebarWidth, _maxSidebarWidth);
          });
        },
        child: Container(
          width: 1,
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),
      ),
    );
  }

  Widget _buildNavBar(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.lock_fill, color: isDark ? CupertinoColors.white : CupertinoColors.black, size: 18),
          const SizedBox(width: 8),
          Text(
            l10n.myVault,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          ),
          const Spacer(),
          _buildNavButton('新建', CupertinoIcons.add, () => setState(() { _showAddItem = true; _selectedItem = null; _showSettings = false; _editingItem = null; })),
          const SizedBox(width: 8),
          _buildNavButton('锁定', CupertinoIcons.lock_open, () => ref.read(vaultProvider.notifier).lock()),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, VoidCallback onPressed) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CupertinoColors.activeBlue,
      borderRadius: BorderRadius.circular(6),
      minSize: 0,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CupertinoColors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(List<VaultItem> items, bool isDark, AppLocalizations l10n, VaultState vaultState) {
    return Column(
      children: [
        _buildSearchBar(isDark, l10n),
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemGroupedBackground,
            child: items.isEmpty
                ? _buildEmptyListState(isDark, l10n)
                : _buildListView(items, isDark, vaultState),
          ),
        ),
        _buildSettingsButton(isDark),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white.withValues(alpha: 0.1) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoTextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 14),
          placeholder: '搜索',
          placeholderStyle: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4), fontSize: 14),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(CupertinoIcons.search, color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4), size: 16),
          ),
          decoration: null,
          padding: const EdgeInsets.symmetric(vertical: 5),
        ),
      ),
    );
  }

  Widget _buildEmptyListState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.lock, size: 48, color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(l10n.noPasswords, style: TextStyle(color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.3), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildListView(List<VaultItem> items, bool isDark, VaultState vaultState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildListItem(items[index], isDark, vaultState),
    );
  }

  Widget _buildListItem(VaultItem item, bool isDark, VaultState vaultState) {
    String? domain;
    if (item.url != null && item.url!.isNotEmpty) {
      try {
        String urlStr = item.url!;
        if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) urlStr = 'https://$urlStr';
        final uri = Uri.parse(urlStr);
        domain = uri.host.isNotEmpty ? uri.host : null;
      } catch (_) {}
    }

    String displayChar = item.title.isNotEmpty ? item.title[0].toUpperCase() : (domain != null && domain.isNotEmpty ? domain[0].toUpperCase() : '?');
    String? subtitle = item.username?.isNotEmpty == true ? item.username : (domain ?? null);
    final isSelected = _selectedItem?.id == item.id;
    final color = _getColorForChar(displayChar);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: () => setState(() { _selectedItem = item; _showSettings = false; _showAddItem = false; _editingItem = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CupertinoColors.activeBlue.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildIcon(color, displayChar, domain),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(subtitle, style: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.5) : CupertinoColors.black.withValues(alpha: 0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color, String displayChar, String? domain) {
    if (domain != null && domain.isNotEmpty) {
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: 'https://$domain/favicon.ico', width: 28, height: 28, fit: BoxFit.cover,
            placeholder: (_, __) => _buildFallbackIcon(color, displayChar),
            errorWidget: (_, __, ___) => _buildFallbackIcon(color, displayChar),
          ),
        ),
      );
    }
    return _buildFallbackIcon(color, displayChar);
  }

  Widget _buildFallbackIcon(Color color, String displayChar) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
      child: Center(child: Text(displayChar[0].toUpperCase(), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildSettingsButton(bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), width: 1)),
      ),
      child: GestureDetector(
        onTap: () => _showSettingsDialog(context, isDark),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(CupertinoIcons.settings, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 8),
              Text('设置', style: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      color: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.lock, size: 64, color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('请选择左侧条目查看详情', style: TextStyle(color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.25), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Color _getColorForChar(String char) {
    final colors = [const Color(0xFF007AFF), const Color(0xFF34C759), const Color(0xFFFF9500), const Color(0xFFAF52DE), const Color(0xFFFF3B30), const Color(0xFF5AC8FA), const Color(0xFFFF2D55), const Color(0xFF5856D6), const Color(0xFF00C7BE), const Color(0xFFFFCC00)];
    return colors[char.toUpperCase().codeUnitAt(0) % colors.length];
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.appTitle),
        content: Text(l10n.aboutDescription),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}

class Colors {
  static const transparent = Color(0x00000000);
}
