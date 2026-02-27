import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/src/dart/vault.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'package:note_password/presentation/providers/vault_provider.dart';
import 'package:note_password/presentation/pages/mobile/edit_page.dart';
import 'package:note_password/presentation/pages/desktop/large_password_dialog.dart';

class DetailPanel extends ConsumerStatefulWidget {
  final VaultItem item;
  final Function(VaultItem)? onEdit;
  final VoidCallback? onDelete;

  const DetailPanel({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<DetailPanel> {
  late VaultItem _item;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void didUpdateWidget(DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _item = widget.item;
      _obscurePassword = true;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final l10n = AppLocalizations.of(context)!;
    _showToast(context, l10n.copied(label));
  }

  void _copyAll() {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer();
    if (_item.username != null && _item.username!.isNotEmpty) {
      buffer.writeln('${l10n.username}: ${_item.username}');
    }
    if (_item.password != null && _item.password!.isNotEmpty) {
      buffer.writeln('${l10n.password}: ${_item.password}');
    }
    if (_item.url != null && _item.url!.isNotEmpty) {
      buffer.writeln('${l10n.url}: ${_item.url}');
    }
    if (_item.notes != null && _item.notes!.isNotEmpty) {
      buffer.writeln('${l10n.notes}:\n${_item.notes}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    _showToast(context, l10n.allDetailsCopied);
  }

  void _showToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      color: isDark ? CupertinoColors.black : const Color(0xFFF2F2F7),
      child: Column(
        children: [
          // 顶部导航栏 - 带编辑按钮
          _buildTopBar(isDark, l10n),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // URL 区域
                  if (_item.url != null && _item.url!.isNotEmpty)
                    _buildUrlSection(isDark, l10n),
                  // 凭据区域
                  _buildCredentialsSection(isDark, l10n),
                  // 备注区域
                  if (_item.notes != null && _item.notes!.isNotEmpty)
                    _buildNotesSection(isDark, l10n),
                  // 附件区域
                  if (_item.attachments.isNotEmpty)
                    _buildAttachmentsSection(isDark, l10n),
                  const SizedBox(height: 24),
                  // 复制所有按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: _copyAll,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.doc_on_doc, size: 18, color: CupertinoColors.white),
                            const SizedBox(width: 8),
                            Text(l10n.copyAll, style: const TextStyle(color: CupertinoColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _item.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _handleDelete,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '删除',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              widget.onEdit?.call(_item);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.activeBlue,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '编辑',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildCard(
        isDark: isDark,
        children: [
          _buildListTile(
            icon: CupertinoIcons.globe,
            title: l10n.url,
            value: _item.url!,
            isDark: isDark,
            onCopy: () => _copyToClipboard(_item.url!, l10n.url),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _buildCard(
        isDark: isDark,
        header: l10n.credentials.toUpperCase(),
        children: [
          _buildListTile(
            icon: CupertinoIcons.person,
            title: l10n.username,
            value: _item.username ?? l10n.notSet,
            isDark: isDark,
            onCopy: _item.username != null
                ? () => _copyToClipboard(_item.username!, l10n.username)
                : null,
          ),
          _buildDivider(isDark),
          _buildPasswordTile(isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _buildCard(
        isDark: isDark,
        header: l10n.notes.toUpperCase(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _item.notes!,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _buildCard(
        isDark: isDark,
        header: l10n.attachments.toUpperCase(),
        children: _item.attachments.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;
          return Column(
            children: [
              CupertinoListTile(
                leading: Icon(CupertinoIcons.doc,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.7)
                        : CupertinoColors.black.withValues(alpha: 0.54)),
                title: Text(a.name,
                    style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                trailing:
                    const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey3),
                onTap: () => _openAttachment(a),
              ),
              if (index < _item.attachments.length - 1) _buildDivider(isDark),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    String? header,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Text(
              header,
              style: TextStyle(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.black.withValues(alpha: 0.54),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 52),
      color: isDark
          ? CupertinoColors.white.withValues(alpha: 0.1)
          : CupertinoColors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.7)
                : CupertinoColors.black.withValues(alpha: 0.54),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : CupertinoColors.black.withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_on_doc,
                  color: CupertinoColors.activeBlue, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordTile(bool isDark, AppLocalizations l10n) {
    final displayValue = _obscurePassword ? '••••••••' : (_item.password ?? l10n.notSet);
    final isEmpty = _item.password == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.lock,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.7)
                : CupertinoColors.black.withValues(alpha: 0.54),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.password,
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : CupertinoColors.black.withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16,
                    fontFamily: _obscurePassword ? 'Courier' : null,
                  ),
                ),
              ],
            ),
          ),
          if (!isEmpty) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                color: CupertinoColors.activeBlue,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.arrow_up_left_square,
                  color: CupertinoColors.activeBlue, size: 18),
              onPressed: () => LargePasswordDialog.show(context, _item.password!),
            ),
          ],
          if (_item.password != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_on_doc,
                  color: CupertinoColors.activeBlue, size: 18),
              onPressed: () => _copyToClipboard(_item.password!, l10n.password),
            ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(Attachment attachment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Implementation would open the attachment
      _showToast(context, 'Opening: ${attachment.name}');
    } catch (e) {
      _showToast(context, l10n.couldNotOpenFile);
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteWarning),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(vaultProvider.notifier).deleteItem(_item.id);
      widget.onDelete?.call();
    }
  }
}
