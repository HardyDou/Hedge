import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'package:note_password/src/dart/vault.dart';
import '../providers/vault_provider.dart';
import 'dart:io';

class AddItemPage extends ConsumerStatefulWidget {
  const AddItemPage({super.key});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  List<Attachment> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _attachments.add(Attachment(
          name: result.files.single.name,
          data: bytes,
        ));
      });
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.titleHint),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newItem = VaultItem(
      title: _titleController.text,
      username: _usernameController.text.isEmpty ? null : _usernameController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      url: _urlController.text.isEmpty ? null : _urlController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      category: null,
      attachments: _attachments,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(vaultProvider.notifier).addItemWithDetails(newItem);
    if (mounted) Navigator.pop(context);
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
        title: Text(l10n.newEntry),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _handleSave,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: const Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.basicInfo.toUpperCase(),
            children: [
              _iOSTextField(
                label: l10n.title,
                controller: _titleController,
                placeholder: l10n.titleHint,
                icon: CupertinoIcons.textformat,
                isDark: isDark,
                autofocus: true,
              ),
              _iOSTextField(
                label: l10n.username,
                controller: _usernameController,
                placeholder: l10n.usernameHint,
                icon: CupertinoIcons.person,
                isDark: isDark,
              ),
              _iOSTextField(
                label: l10n.password,
                controller: _passwordController,
                placeholder: l10n.passwordHint,
                icon: CupertinoIcons.lock,
                isDark: isDark,
                isPassword: true,
                showPasswordToggle: true,
              ),
              _iOSTextField(
                label: l10n.url,
                controller: _urlController,
                placeholder: 'https://',
                icon: CupertinoIcons.link,
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.notes.toUpperCase(),
            children: [
              _iOSTextField(
                label: l10n.notes,
                controller: _notesController,
                placeholder: l10n.notesHint,
                icon: CupertinoIcons.doc_text,
                isDark: isDark,
                maxLines: 4,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.attachments.toUpperCase(),
            children: [
              if (_attachments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.noAttachments,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._attachments.map((a) => _iOSAttachmentTile(
                  name: a.name,
                  onDelete: () {
                    setState(() {
                      _attachments.remove(a);
                    });
                  },
                  isDark: isDark,
                  showDivider: _attachments.last != a,
                )),
              _iOSListTile(
                title: l10n.addFile,
                leading: CupertinoIcons.add_circled,
                onTap: _pickAttachment,
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildiOSSection({
    required BuildContext context,
    required String header,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
          child: Text(
            header,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _iOSTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool isDark;
  final bool isPassword;
  final bool showPasswordToggle;
  final int maxLines;
  final bool showDivider;
  final bool autofocus;

  const _iOSTextField({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.isDark,
    this.isPassword = false,
    this.showPasswordToggle = false,
    this.maxLines = 1,
    this.showDivider = true,
    this.autofocus = false,
  });

  @override
  State<_iOSTextField> createState() => _iOSTextFieldState();
}

class _iOSTextFieldState extends State<_iOSTextField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bool actualObscured = widget.isPassword && !_isVisible && !widget.showPasswordToggle;

    return Container(
      decoration: BoxDecoration(
        border: widget.showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  widget.icon,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: actualObscured,
                    maxLines: widget.isPassword ? 1 : widget.maxLines,
                    autofocus: widget.autofocus,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.showPasswordToggle)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isVisible = !_isVisible;
                      });
                    },
                    child: Icon(
                      _isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _iOSListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leading;
  final VoidCallback? onTap;
  final bool isDark;
  final bool showDivider;
  final Widget? trailing;

  const _iOSListTile({
    required this.title,
    this.subtitle,
    required this.leading,
    this.onTap,
    required this.isDark,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(leading, color: const Color(0xFF007AFF), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                CupertinoIcons.chevron_right,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _iOSAttachmentTile extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;
  final bool isDark;
  final bool showDivider;

  const _iOSAttachmentTile({
    required this.name,
    required this.onDelete,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.doc,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              CupertinoIcons.minus_circle_fill,
              color: Colors.red.shade400,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
