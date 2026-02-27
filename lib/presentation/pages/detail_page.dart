import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/src/dart/vault.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'edit_page.dart';
import '../providers/vault_provider.dart';
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
    Clipboard.setData(ClipboardData(text: text));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copied(label)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.allDetailsCopied),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _openAttachment(Attachment attachment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${attachment.name}');
      await file.writeAsBytes(attachment.data);
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenFile)),
      );
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(l10n.deleteEntry, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(l10n.deleteWarning, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],      ),
    );

    if (confirmed == true) {
      await ref.read(vaultProvider.notifier).deleteItem(_item.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: Text(_item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
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
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // URL Section
            if (_item.url != null && _item.url!.isNotEmpty)
              _buildiOSSection(
                context: context,
                children: [
                  _buildListTile(
                    icon: Icons.language,
                    title: l10n.url,
                    value: _item.url!,
                    isDark: isDark,
                    onCopy: () => _copyToClipboard(_item.url!, l10n.url),
                  ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // Credentials Section
            _buildiOSSection(
              context: context,
              header: l10n.credentials.toUpperCase(),
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: l10n.username,
                  value: _item.username ?? l10n.notSet,
                  isDark: isDark,
                  onCopy: _item.username != null ? () => _copyToClipboard(_item.username!, l10n.username) : null,
                ),
                _buildDivider(isDark),
                _buildPasswordTile(
                  icon: Icons.lock_outline,
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
            
            // Notes Section
            if (_item.notes != null && _item.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildiOSSection(
                context: context,
                header: l10n.notes.toUpperCase(),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _item.notes!,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Attachments Section
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
                      ListTile(
                        leading: Icon(Icons.insert_drive_file_outlined, color: isDark ? Colors.white70 : Colors.black54),
                        title: Text(a.name, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black12),
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
            
            // Copy All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _copyAll,
                  icon: const Icon(Icons.copy_all),
                  label: Text(l10n.copyAll),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
            child: Text(
              header,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    VoidCallback? onCopy,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 22),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
      ),
      trailing: onCopy != null
          ? SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.copy, color: Color(0xFF007AFF), size: 18),
                onPressed: onCopy,
              ),
            )
          : null,
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
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 22),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
      ),
      subtitle: Text(
        displayValue,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontFamily: isObscured ? 'Courier' : null,
        ),
      ),
      trailing: !isEmpty || onCopy != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isEmpty) ...[
                  _CompactIconButton(
                    icon: isObscured ? Icons.visibility : Icons.visibility_off,
                    onPressed: onToggleObscure,
                  ),
                  _CompactIconButton(
                    icon: Icons.fullscreen,
                    onPressed: onEnlarge,
                  ),
                ],
                if (onCopy != null)
                  _CompactIconButton(
                    icon: Icons.copy,
                    onPressed: onCopy,
                  ),
              ],
            )
          : null,
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CompactIconButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: const Color(0xFF007AFF), size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
