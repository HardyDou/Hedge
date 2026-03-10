import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/widgets/markdown_toolbar.dart';
import 'package:hedge/presentation/pages/desktop/desktop_qr_scanner_dialog.dart';
import 'package:hedge/presentation/widgets/password_generator_popover.dart';
import 'package:hedge/core/theme/app_colors.dart';

class EditPanel extends ConsumerStatefulWidget {
  final VaultItem item;
  final VoidCallback onClose;
  final Function(VaultItem) onSave;

  const EditPanel({super.key, required this.item, required this.onClose, required this.onSave});

  @override
  ConsumerState<EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends ConsumerState<EditPanel> {
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  bool _isLoading = false;
  bool _notesPreview = false;
  bool _passwordVisible = true;
  String? _totpSecret;
  String? _totpIssuer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _usernameController = TextEditingController(text: widget.item.username ?? '');
    _passwordController = TextEditingController(text: widget.item.password ?? '');
    _urlController = TextEditingController(text: widget.item.url ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _notesPreview = widget.item.notes?.isNotEmpty ?? false;
    _totpSecret = widget.item.totpSecret;
    _totpIssuer = widget.item.totpIssuer;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppColors.isDark(context);

    return Container(
      color: AppColors.surface2.resolveFrom(context),
      child: Column(
        children: [
          _buildHeader(isDark, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('标题', _titleController, isDark, placeholder: '必填'),
                  const SizedBox(height: 16),
                  _buildTextField('用户名', _usernameController, isDark),
                  const SizedBox(height: 16),
                  _buildPasswordField(isDark, l10n),
                  const SizedBox(height: 16),
                  _buildTextField('网址', _urlController, isDark, placeholder: 'https://'),
                  const SizedBox(height: 16),
                  _buildTotpSection(isDark, l10n),
                  const SizedBox(height: 16),
                  _buildNotesSection(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface1.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.1) : CupertinoColors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onClose,
            child: Text('取消', style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 16)),
          ),
          const Spacer(),
          Text('编辑密码', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : Text('保存', style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {bool isPassword = false, int maxLines = 1, String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          placeholder: placeholder,
          style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
          placeholderStyle: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3)),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface1.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.black.withValues(alpha: 0.1)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '密码',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.black.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () async {
                final password = await PasswordGeneratorPopover.show(context);
                if (password != null) {
                  _passwordController.text = password;
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.wand_stars,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.generate,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            CupertinoTextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              placeholder: '密码',
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              placeholderStyle: TextStyle(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.3)
                    : CupertinoColors.black.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12, right: 40),
              decoration: BoxDecoration(
                color: AppColors.surface1.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.2)
                      : CupertinoColors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
                child: Icon(
                  _passwordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.6)
                      : CupertinoColors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildNotesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('备注', style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6))),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => setState(() => _notesPreview = !_notesPreview),
              child: Text(
                _notesPreview ? '编辑' : '预览',
                style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.black.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              MarkdownToolbar(
                controller: _notesController,
                isDark: isDark,
                isPreview: _notesPreview,
              ),
              _notesPreview
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: SizedBox(
                          width: double.infinity,
                          child: _notesController.text.isEmpty
                              ? Text(
                                  '暂无内容',
                                  style: TextStyle(
                                    color: isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3),
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
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: CupertinoTextField(
                        controller: _notesController,
                        maxLines: null,
                        minLines: 5,
                        padding: EdgeInsets.zero,
                        style: TextStyle(
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        placeholder: '输入备注...',
                        placeholderStyle: TextStyle(
                          color: isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3),
                          fontSize: 15,
                        ),
                        decoration: const BoxDecoration(),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) {
      _showError('请输入标题');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedItem = widget.item.copyWith(
        title: _titleController.text,
        username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        url: _urlController.text.isNotEmpty ? _urlController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        totpSecret: _totpSecret,
        totpIssuer: _totpIssuer,
        updatedAt: DateTime.now(),
      );

      await ref.read(vaultProvider.notifier).updateItem(updatedItem);
      widget.onSave(updatedItem);
    } catch (e) {
      _showError('保存失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(content: Text(message)),
    );
  }

  Widget _buildTotpSection(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.totp.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_totpSecret != null) ...[
                _buildTotpInfoTile(
                  isDark,
                  l10n.totpSecret,
                  '••••••••',
                  CupertinoIcons.timer,
                ),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 16),
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.1)
                      : CupertinoColors.black.withValues(alpha: 0.1),
                ),
                if (_totpIssuer != null && _totpIssuer!.isNotEmpty) ...[
                  _buildTotpInfoTile(
                    isDark,
                    l10n.totpIssuer,
                    _totpIssuer!,
                    CupertinoIcons.building_2_fill,
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 16),
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.1),
                  ),
                ],
                _buildTotpActionTile(
                  isDark,
                  l10n.deleteTotp,
                  CupertinoIcons.trash,
                  CupertinoColors.destructiveRed,
                  () => _showDeleteTotpConfirm(l10n),
                ),
              ] else ...[
                _buildTotpActionTile(
                  isDark,
                  l10n.scanQrCode,
                  CupertinoIcons.qrcode_viewfinder,
                  CupertinoColors.activeBlue,
                  () => _showQrScanner(l10n),
                ),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 16),
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.1)
                      : CupertinoColors.black.withValues(alpha: 0.1),
                ),
                _buildTotpActionTile(
                  isDark,
                  l10n.manualInput,
                  CupertinoIcons.keyboard,
                  CupertinoColors.activeBlue,
                  () => _showManualInputDialog(l10n, isDark),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotpInfoTile(bool isDark, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CupertinoColors.systemGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotpActionTile(bool isDark, String title, IconData icon, Color color, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: color,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: color,
          ),
        ],
      ),
    );
  }

  Future<void> _showQrScanner(AppLocalizations l10n) async {
    final result = await showCupertinoDialog<Map<String, String>>(
      context: context,
      builder: (context) => const DesktopQrScannerDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _totpSecret = result['secret'];
        _totpIssuer = result['issuer']?.isEmpty == true ? null : result['issuer'];
      });
    }
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
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: issuerController,
              placeholder: l10n.totpIssuerHint,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
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
}
