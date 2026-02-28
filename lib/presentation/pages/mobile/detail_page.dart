import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'edit_page.dart';
import '../../providers/vault_provider.dart';
import 'large_password_page.dart' show LargePasswordPage;

class DetailPage extends ConsumerStatefulWidget {
  final VaultItem item;
  const DetailPage({super.key, required this.item});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  late VaultItem _item;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _copyToClipboard(String text, String label) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(vaultProvider.notifier).copyPassword(_item.id);
    _showToast(context, l10n.copied(label));
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

  void _copyAll() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(vaultProvider.notifier).copyAllCredentials(_item.id, l10n);
    _showToast(context, l10n.allDetailsCopied);
  }

  Future<void> _openAttachment(Attachment attachment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${attachment.name}');
      await file.writeAsBytes(attachment.data);
      await OpenFile.open(file.path);
    } catch (e) {
      _showToast(context, l10n.couldNotOpenFile);
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
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
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        middle: Text(_item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: () async {
                final result = await Navigator.push<VaultItem>(
                  context,
                  CupertinoPageRoute(builder: (context) => EditPage(item: _item)),
                );
                if (result != null) {
                  setState(() => _item = result);
                }
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
              onPressed: _handleDelete,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            if (_item.url != null && _item.url!.isNotEmpty)
              _buildiOSSection(
                context: context,
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
            
            const SizedBox(height: 20),
            
            _buildiOSSection(
              context: context,
              header: l10n.credentials.toUpperCase(),
              children: [
                _buildListTile(
                  icon: CupertinoIcons.person,
                  title: l10n.username,
                  value: _item.username ?? l10n.notSet,
                  isDark: isDark,
                  onCopy: _item.username != null ? () => _copyToClipboard(_item.username!, l10n.username) : null,
                ),
                _buildDivider(isDark),
                _buildPasswordTile(
                  icon: CupertinoIcons.lock,
                  title: l10n.password,
                  value: _item.password ?? l10n.notSet,
                  isDark: isDark,
                  isObscured: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  onCopy: _item.password != null ? () => _copyToClipboard(_item.password!, l10n.password) : null,
                  onEnlarge: _item.password != null ? () {
                    LargePasswordPage.show(context, _item.password!);
                  } : null,
                ),
              ],
            ),
            
            if (_item.notes != null && _item.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildiOSSection(
                context: context,
                header: l10n.notes.toUpperCase(),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: CupertinoTextField(
                      controller: TextEditingController(text: _item.notes),
                      readOnly: true,
                      maxLines: null,
                      decoration: null,
                      padding: EdgeInsets.zero,
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 15,
                      ),
                      enableInteractiveSelection: true,
                    ),
                  ),
                ],
              ),
            ],
            
            if (_item.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildiOSSection(
                context: context,
                header: l10n.attachments.toUpperCase(),
                children: _item.attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final a = entry.value;
                  return Column(
                    children: [
                      CupertinoListTile(
                        leading: Icon(CupertinoIcons.doc, color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54)),
                        title: Text(a.name, style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey3),
                        onTap: () => _openAttachment(a),
                      ),
                      if (index < _item.attachments.length - 1)
                        _buildDivider(isDark),
                    ],
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _copyAll,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_on_doc, color: isDark ? CupertinoColors.black : CupertinoColors.white),
                      const SizedBox(width: 8),
                      Text(l10n.copyAll, style: TextStyle(color: isDark ? CupertinoColors.black : CupertinoColors.white)),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildiOSSection({
    required BuildContext context,
    String? header,
    required List<Widget> children,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
            child: Text(
              header,
              style: TextStyle(
                color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.54),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
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
      color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.54), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 16),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.activeBlue, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required bool isObscured,
    VoidCallback? onToggleObscure,
    VoidCallback? onCopy,
    VoidCallback? onEnlarge,
  }) {
    final displayValue = isObscured ? '••••••••' : value;
    final isEmpty = value == 'Not set';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.54), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16,
                    fontFamily: isObscured ? 'Courier' : null,
                  ),
                ),
              ],
            ),
          ),
          if (!isEmpty) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(isObscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: CupertinoColors.activeBlue, size: 18),
              onPressed: onToggleObscure,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.arrow_up_left_square, color: CupertinoColors.activeBlue, size: 18),
              onPressed: onEnlarge,
            ),
          ],
          if (onCopy != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.activeBlue, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
