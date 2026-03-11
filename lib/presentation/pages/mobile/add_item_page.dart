import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/presentation/widgets/markdown_toolbar.dart';
import 'package:hedge/presentation/pages/mobile/qr_scanner_page.dart';
import 'package:hedge/domain/services/qr_scanner_service.dart';
import 'package:hedge/presentation/widgets/password_generator_sheet.dart';
import 'package:hedge/core/theme/app_colors.dart';
import '../../providers/vault_provider.dart';
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
  bool _notesPreview = false;
  String? _totpSecret;
  String? _totpIssuer;

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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(AppLocalizations.of(context)!.titleHint),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
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
      totpSecret: _totpSecret,
      totpIssuer: _totpIssuer,
      attachments: _attachments,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(vaultProvider.notifier).addItemWithDetails(newItem);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppColors.isDark(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000), // Transparent
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.surface2.resolveFrom(context),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: CupertinoPageScaffold(
      backgroundColor: AppColors.surface2.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface1.resolveFrom(context),
        middle: Text(l10n.newEntry),
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
                  showGenerateButton: true,
                  onGeneratePassword: () async {
                    final password = await PasswordGeneratorSheet.show(context);
                    if (password != null) {
                      setState(() {
                        _passwordController.text = password;
                      });
                    }
                  },
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
            _buildTotpSection(context, l10n, isDark),
            const SizedBox(height: 32),
            _buildNotesSection(context, l10n, isDark),
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
                        color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.4),
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

  Widget _buildTotpSection(BuildContext context, AppLocalizations l10n, bool isDark) {
    return _buildiOSSection(
      context: context,
      header: l10n.totp.toUpperCase(),
      children: [
        if (_totpSecret != null) ...[
          _iOSListTile(
            title: l10n.totpSecret,
            subtitle: '••••••••',
            leading: CupertinoIcons.timer,
            isDark: isDark,
            showDivider: true,
          ),
          if (_totpIssuer != null && _totpIssuer!.isNotEmpty)
            _iOSListTile(
              title: l10n.totpIssuer,
              subtitle: _totpIssuer,
              leading: CupertinoIcons.building_2_fill,
              isDark: isDark,
              showDivider: true,
            ),
          _iOSListTile(
            title: l10n.deleteTotp,
            leading: CupertinoIcons.trash,
            onTap: () => _showDeleteTotpConfirm(l10n),
            isDark: isDark,
            showDivider: false,
            trailing: const Icon(
              CupertinoIcons.chevron_forward,
              color: CupertinoColors.destructiveRed,
              size: 16,
            ),
          ),
        ] else ...[
          _iOSListTile(
            title: l10n.scanQrCode,
            leading: CupertinoIcons.qrcode_viewfinder,
            onTap: () => _showQrScanPlaceholder(l10n),
            isDark: isDark,
            showDivider: true,
          ),
          _iOSListTile(
            title: l10n.selectImage,
            leading: CupertinoIcons.photo,
            onTap: () => _pickImageForQrScan(l10n),
            isDark: isDark,
            showDivider: true,
          ),
          _iOSListTile(
            title: l10n.manualInput,
            leading: CupertinoIcons.keyboard,
            onTap: () => _showManualInputDialog(l10n, isDark),
            isDark: isDark,
            showDivider: false,
          ),
        ],
      ],
    );
  }

  Future<void> _showManualInputDialog(AppLocalizations l10n, bool isDark) async {
    final secretController = TextEditingController(text: _totpSecret ?? '');
    final issuerController = TextEditingController(text: _totpIssuer ?? '');

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.manualInput),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: secretController,
              placeholder: l10n.totpSecret,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: issuerController,
              placeholder: l10n.totpIssuerHint,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (secretController.text.isNotEmpty) {
                setState(() {
                  _totpSecret = secretController.text.trim().toUpperCase().replaceAll(' ', '');
                  _totpIssuer = issuerController.text.trim().isEmpty ? null : issuerController.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    secretController.dispose();
    issuerController.dispose();
  }

  Future<void> _showDeleteTotpConfirm(AppLocalizations l10n) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteTotp),
        content: Text(l10n.deleteTotpConfirm),
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

    if (result == true) {
      setState(() {
        _totpSecret = null;
        _totpIssuer = null;
      });
    }
  }

  Future<void> _showQrScanPlaceholder(AppLocalizations l10n) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      CupertinoPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _totpSecret = result['secret'];
        _totpIssuer = result['issuer']?.isEmpty == true ? null : result['issuer'];
      });
    }
  }

  Future<void> _pickImageForQrScan(AppLocalizations l10n) async {
    try {
      final result = await QrScannerService.scanFromImage();

      if (result == null) {
        if (mounted) {
          _showErrorDialog(l10n.scanFailed, l10n.invalidQrCode);
        }
        return;
      }

      final totpData = QrScannerService.parseTotpUri(result);

      if (totpData != null && mounted) {
        setState(() {
          _totpSecret = totpData['secret'];
          _totpIssuer = totpData['issuer']?.isEmpty == true ? null : totpData['issuer'];
        });
      } else if (mounted) {
        _showErrorDialog(l10n.scanFailed, l10n.invalidQrCode);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(l10n.error, e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, AppLocalizations l10n, bool isDark) {
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
              if (_notesController.text.isNotEmpty)
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
            color: AppColors.surface1.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: _notesController.text.isEmpty
              ? GestureDetector(
                  onTap: () => _openFullscreen(context, isDark),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          l10n.notesHint,
                          style: TextStyle(
                            color: isDark ? CupertinoColors.white.withValues(alpha: 0.24) : CupertinoColors.black.withValues(alpha: 0.26),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: SizedBox(
                      width: double.infinity,
                      child: MarkdownBody(
                        data: _notesController.text,
                        selectable: true,
                        fitContent: false,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 15, height: 1.5),
                          strong: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontWeight: FontWeight.bold),
                          em: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontStyle: FontStyle.italic),
                          code: TextStyle(
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            backgroundColor: AppColors.surface2.resolveFrom(context),
                            fontSize: 13,
                            fontFamily: 'Courier',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.surface2.resolveFrom(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          listBullet: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 15),
                        ),
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
    final isDark = AppColors.isDark(context);
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
            color: AppColors.surface1.resolveFrom(context),
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
  final bool showGenerateButton;
  final VoidCallback? onGeneratePassword;
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
    this.showGenerateButton = false,
    this.onGeneratePassword,
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
    final bool actualObscured = widget.isPassword && !_isVisible;

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
                    autofocus: widget.autofocus,
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
                if (widget.showGenerateButton)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minSize: 44,
                    onPressed: widget.onGeneratePassword,
                    child: const Icon(
                      CupertinoIcons.wand_stars,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                  ),
                if (widget.showPasswordToggle)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minSize: 44,
                    onPressed: () {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: widget.isDark ? const Color(0xFF000000) : AppColors.surface2.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface1.resolveFrom(context),
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
                              color: AppColors.surface1.resolveFrom(context),
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
                      color: AppColors.surface1.resolveFrom(context),
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
