import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hedge/src/dart/vault.dart';
import 'dart:io';
import 'dart:async';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/domain/services/totp_service.dart';
import 'package:hedge/core/theme/app_colors.dart';
import 'edit_page.dart';
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
  Timer? _totpTimer;
  Timer? _clipboardTimer;

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
    _clipboardTimer?.cancel();
    super.dispose();
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

  void _copyTotp(String code) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: code));
    _showToast(context, l10n.totpCopied);

    // 30 秒后清空剪贴板
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
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
    final brightness = CupertinoTheme.of(context).brightness ??
                       MediaQuery.platformBrightnessOf(context);
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
            
            Builder(builder: (_) {
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
                children.add(_buildPasswordTile(
                  icon: CupertinoIcons.lock,
                  title: l10n.password,
                  value: _item.password!,
                  isDark: isDark,
                  isObscured: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  onCopy: () => _copyToClipboard(_item.password!, l10n.password),
                  onEnlarge: () => LargePasswordPage.show(context, _item.password!),
                ));
              }
              // TOTP 显示
              if (_item.totpSecret != null) {
                if (children.isNotEmpty) children.add(_buildDivider(isDark));
                children.add(_buildTotpTile(isDark, l10n));
              }
              return _buildiOSSection(
                context: context,
                header: l10n.credentials.toUpperCase(),
                children: children,
              );
            }),
            
            if (_item.notes != null && _item.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildiOSSection(
                context: context,
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
                          styleSheet: _markdownStyle(isDark),
                        ),
                      ),
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
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(bool isDark) {
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final codeBackground = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return MarkdownStyleSheet(
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
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildiOSSection({
    required BuildContext context,
    String? header,
    required List<Widget> children,
  }) {
    final isDark = AppColors.isDark(context);
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
            color: AppColors.surface1.resolveFrom(context),
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

  Widget _buildTotpTile(bool isDark, AppLocalizations l10n) {
    try {
      final code = TotpService.generateTotp(_item.totpSecret!);
      final formattedCode = TotpService.formatCode(code);
      final remaining = TotpService.getRemainingSeconds();
      final progress = TotpService.getProgress();

      return GestureDetector(
        onLongPress: () => _showTotpActionSheet(l10n),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onPressed: () => _copyTotp(code),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      );
    }
  }

  void _showTotpActionSheet(AppLocalizations l10n) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              // TODO: 导航到编辑页面
            },
            child: Text(l10n.editTotp),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final confirmed = await showCupertinoDialog<bool>(
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

              if (confirmed == true) {
                // 创建新的 VaultItem，将 totpSecret 和 totpIssuer 设置为 null
                final updatedItem = VaultItem(
                  id: _item.id,
                  title: _item.title,
                  titlePinyin: _item.titlePinyin,
                  username: _item.username,
                  password: _item.password,
                  url: _item.url,
                  notes: _item.notes,
                  category: _item.category,
                  totpSecret: null,
                  totpIssuer: null,
                  attachments: _item.attachments,
                  createdAt: _item.createdAt,
                  updatedAt: DateTime.now(),
                );
                await ref.read(vaultProvider.notifier).updateItem(updatedItem);
                setState(() {
                  _item = updatedItem;
                  _totpTimer?.cancel();
                });
              }
            },
            child: Text(l10n.deleteTotp),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
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
