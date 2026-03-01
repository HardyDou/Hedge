import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/presentation/widgets/markdown_toolbar.dart';
import '../../providers/vault_provider.dart';

class EditPage extends ConsumerStatefulWidget {
  final VaultItem item;
  const EditPage({super.key, required this.item});

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  late List<Attachment> _attachments;
  late bool _notesPreview;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _usernameController = TextEditingController(text: widget.item.username);
    _passwordController = TextEditingController(text: widget.item.password);
    _urlController = TextEditingController(text: widget.item.url);
    _notesController = TextEditingController(text: widget.item.notes);
    _attachments = List.from(widget.item.attachments);
    _notesPreview = widget.item.notes?.isNotEmpty ?? false;
  }

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
    if (_titleController.text.isEmpty) return;

    final updatedItem = VaultItem(
      id: widget.item.id,
      title: _titleController.text,
      username: _usernameController.text.isEmpty ? null : _usernameController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      url: _urlController.text.isEmpty ? null : _urlController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      category: widget.item.category,
      attachments: _attachments,
      updatedAt: DateTime.now(),
    );

    await ref.read(vaultProvider.notifier).updateItem(updatedItem);
    if (mounted) Navigator.pop(context, updatedItem);
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
        middle: Text(l10n.editEntry),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: _handleSave,
          child: Text(
            l10n.save,
            style: const TextStyle(
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
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
            _buildNotesSectionWithPreview(context, l10n, isDark),
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
                        color: isDark ? CupertinoColors.white.withOpacity(0.4) : CupertinoColors.black.withOpacity(0.4),
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
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(bool isDark) {
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final codeBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
      strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
      code: TextStyle(color: textColor, backgroundColor: codeBg, fontSize: 13, fontFamily: 'Courier'),
      codeblockDecoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(6)),
      listBullet: TextStyle(color: textColor, fontSize: 15),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.black.withValues(alpha: 0.2))),
      ),
    );
  }

  Future<void> _openFullscreen(BuildContext context, bool isDark) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => _FullscreenNotesEditor(controller: _notesController, isDark: isDark),
      ),
    );
  }

  Widget _buildNotesSectionWithPreview(
      BuildContext context, AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
          child: Row(
            children: [
              Text(
                l10n.notes.toUpperCase(),
                style: TextStyle(
                  color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.54),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => _openFullscreen(context, isDark),
                child: const Text(
                  '编辑',
                  style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: SizedBox(
                width: double.infinity,
                child: _notesController.text.isEmpty
                    ? Text(
                        l10n.notesHint,
                        style: TextStyle(
                          color: isDark ? CupertinoColors.white.withValues(alpha: 0.24) : CupertinoColors.black.withValues(alpha: 0.26),
                          fontSize: 15,
                        ),
                      )
                    : MarkdownBody(
                        data: _notesController.text,
                        selectable: true,
                        fitContent: false,
                        styleSheet: _markdownStyle(isDark),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildiOSSection({
    required BuildContext context,
    required String header,
    required List<Widget> children,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
          child: Text(
            header,
            style: TextStyle(
              color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.54),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
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
                  color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.06),
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
                color: isDark ? CupertinoColors.white.withOpacity(0.4) : CupertinoColors.black.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  widget.icon,
                  color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoTextField(
                    controller: widget.controller,
                    obscureText: actualObscured,
                    maxLines: widget.isPassword ? 1 : widget.maxLines,
                    padding: EdgeInsets.zero,
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                    ),
                    placeholder: widget.placeholder,
                    placeholderStyle: TextStyle(
                      color: isDark ? CupertinoColors.white.withOpacity(0.24) : CupertinoColors.black.withOpacity(0.26),
                      fontSize: 16,
                    ),
                    decoration: const BoxDecoration(),
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
                      color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
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
                    color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.06),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(leading, color: CupertinoColors.activeBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
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
                CupertinoIcons.chevron_forward,
                color: isDark ? CupertinoColors.white.withOpacity(0.25) : CupertinoColors.black.withOpacity(0.25),
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
                  color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.06),
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
            color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              CupertinoIcons.minus_circle_fill,
              color: CupertinoColors.destructiveRed,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenNotesEditor extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;

  const _FullscreenNotesEditor({required this.controller, required this.isDark});

  @override
  State<_FullscreenNotesEditor> createState() => _FullscreenNotesEditorState();
}

class _FullscreenNotesEditorState extends State<_FullscreenNotesEditor> {
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    // 监听文本变化，自动刷新预览
    widget.controller.addListener(() {
      if (_isPreview && mounted) {
        setState(() {});
      }
    });
  }

  MarkdownStyleSheet _markdownStyle() {
    final textColor = widget.isDark ? CupertinoColors.white : CupertinoColors.black;
    final codeBg = widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
      strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
      code: TextStyle(color: textColor, backgroundColor: codeBg, fontSize: 13, fontFamily: 'Courier'),
      codeblockDecoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(6)),
      listBullet: TextStyle(color: textColor, fontSize: 15),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.isDark ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.black.withValues(alpha: 0.2))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: widget.isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: widget.isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        middle: const Text('备注'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _isPreview = !_isPreview),
              child: Text(
                _isPreview ? '编辑' : '预览',
                style: const TextStyle(color: CupertinoColors.activeBlue),
              ),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Text('完成', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            MarkdownToolbar(
              controller: widget.controller,
              isDark: widget.isDark,
              isPreview: _isPreview,
            ),
            Expanded(
              child: _isPreview
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: widget.isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                              child: widget.controller.text.isEmpty
                                  ? Text(
                                      '暂无内容',
                                      style: TextStyle(
                                        color: widget.isDark ? CupertinoColors.white.withValues(alpha: 0.24) : CupertinoColors.black.withValues(alpha: 0.26),
                                        fontSize: 15,
                                      ),
                                    )
                                  : MarkdownBody(
                                      data: widget.controller.text,
                                      selectable: true,
                                      styleSheet: _markdownStyle(),
                                    ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: widget.isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: CupertinoTextField(
                          controller: widget.controller,
                          maxLines: null,
                          minLines: 20,
                          autofocus: true,
                          padding: EdgeInsets.zero,
                          style: TextStyle(
                            color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          placeholder: '输入备注...',
                          placeholderStyle: TextStyle(
                            color: widget.isDark ? CupertinoColors.white.withValues(alpha: 0.24) : CupertinoColors.black.withValues(alpha: 0.26),
                            fontSize: 15,
                          ),
                          decoration: const BoxDecoration(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
