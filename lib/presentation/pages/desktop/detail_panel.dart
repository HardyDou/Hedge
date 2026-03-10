import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/presentation/pages/desktop/large_password_dialog.dart';
import 'package:hedge/domain/services/totp_service.dart';
import 'package:hedge/core/theme/app_colors.dart';

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
  Timer? _totpTimer;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item.totpSecret != null) {
      _startTotpTimer();
    }
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _item = widget.item;
      _obscurePassword = true;
      _totpTimer?.cancel();
      if (_item.totpSecret != null) {
        _startTotpTimer();
      }
    }
  }

  void _startTotpTimer() {
    _totpTimer?.cancel();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 触发 UI 刷新以更新倒计时
        });
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(vaultProvider.notifier).copyPassword(_item.id);
    _showToast(context, l10n.copied(label));
  }

  void _copyAll() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(vaultProvider.notifier).copyAllCredentials(_item.id, l10n);
    _showToast(context, l10n.allDetailsCopied);
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message),
    );

    overlay.insert(overlayEntry);

    // 1.5 秒后自动移除
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppColors.isDark(context);

    return Container(
      color: AppColors.surface2.resolveFrom(context),
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
                  // TOTP 区域
                  if (_item.totpSecret != null)
                    _buildTotpSection(isDark, l10n),
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
        color: AppColors.surface1.resolveFrom(context),
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
    final hasUsername = _item.username != null && _item.username!.isNotEmpty;
    final hasPassword = _item.password != null && _item.password!.isNotEmpty;
    if (!hasUsername && !hasPassword) return const SizedBox.shrink();

    final children = <Widget>[];
    if (hasUsername) {
      children.add(_buildListTile(
        icon: CupertinoIcons.person,
        title: l10n.username,
        value: _item.username!,
        isDark: isDark,
        onCopy: () => _copyToClipboard(_item.username!, l10n.username),
      ));
    }
    if (hasPassword) {
      if (children.isNotEmpty) children.add(_buildDivider(isDark));
      children.add(_buildPasswordTile(isDark, l10n));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _buildCard(
        isDark: isDark,
        header: l10n.credentials.toUpperCase(),
        children: children,
      ),
    );
  }

  Widget _buildNotesSection(bool isDark, AppLocalizations l10n) {
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final codeBackground = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _buildCard(
        isDark: isDark,
        header: l10n.notes.toUpperCase(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: SizedBox(
                width: double.infinity,
                child: MarkdownBody(
                  data: _item.notes!,
                  selectable: true,
                  fitContent: false,
                  styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                code: TextStyle(
                  color: textColor,
                  backgroundColor: codeBackground,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
                codeblockDecoration: BoxDecoration(
                  color: codeBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                listBullet: TextStyle(color: textColor, fontSize: 15),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.2)
                          : CupertinoColors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
                ),
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
            color: AppColors.surface1.resolveFrom(context),
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

  Widget _buildTotpSection(bool isDark, AppLocalizations l10n) {
    try {
      final code = TotpService.generateTotp(_item.totpSecret!);
      final formattedCode = TotpService.formatCode(code);
      final remaining = TotpService.getRemainingSeconds();
      final progress = TotpService.getProgress();

      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
        child: _buildCard(
          isDark: isDark,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.timer,
                    color: isDark
                        ? CupertinoColors.white.withOpacity(0.7)
                        : CupertinoColors.black.withOpacity(0.54),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totp,
                          style: TextStyle(
                            color: isDark
                                ? CupertinoColors.white.withOpacity(0.6)
                                : CupertinoColors.black.withOpacity(0.54),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              formattedCode,
                              style: TextStyle(
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Courier',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '⏱ ${remaining}s',
                              style: TextStyle(
                                color: remaining <= 5
                                    ? CupertinoColors.destructiveRed
                                    : (isDark
                                        ? CupertinoColors.white.withOpacity(0.6)
                                        : CupertinoColors.black.withOpacity(0.54)),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 进度条
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? CupertinoColors.white.withOpacity(0.1)
                                : CupertinoColors.black.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              remaining <= 5
                                  ? CupertinoColors.destructiveRed
                                  : CupertinoColors.activeBlue,
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.doc_on_doc,
                      color: CupertinoColors.activeBlue,
                      size: 18,
                    ),
                    onPressed: () => _copyToClipboard(code, l10n.totp),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
        child: _buildCard(
          isDark: isDark,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: CupertinoColors.destructiveRed,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.totpGenerationFailed,
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
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

/// Toast 提示组件
class _ToastWidget extends StatelessWidget {
  final String message;

  const _ToastWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
