import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';

/// 密码详情弹出面板
class PasswordDetailPopup extends StatelessWidget {
  final VaultItem item;
  final bool isDark;

  const PasswordDetailPopup({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      (item.title ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 标题
                Expanded(
                  child: Text(
                    item.title ?? '',
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 详情内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名
                if (item.username != null && item.username!.isNotEmpty)
                  _buildField(
                    context: context,
                    label: l10n.username,
                    value: item.username!,
                    icon: CupertinoIcons.person,
                    isDark: isDark,
                  ),

                // 密码
                if (item.password != null && item.password!.isNotEmpty)
                  _buildField(
                    context: context,
                    label: l10n.password,
                    value: '••••••••',
                    icon: CupertinoIcons.lock,
                    isDark: isDark,
                    isPassword: true,
                    actualValue: item.password!,
                  ),

                // URL
                if (item.url != null && item.url!.isNotEmpty)
                  _buildField(
                    context: context,
                    label: l10n.url,
                    value: item.url!,
                    icon: CupertinoIcons.globe,
                    isDark: isDark,
                  ),

                // 备注
                if (item.notes != null && item.notes!.isNotEmpty)
                  _buildField(
                    context: context,
                    label: l10n.notes,
                    value: item.notes!,
                    icon: CupertinoIcons.doc_text,
                    isDark: isDark,
                    maxLines: 3,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    String? actualValue,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 值 + 复制按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 复制按钮
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: actualValue ?? value));
                  // TODO: 显示复制成功提示
                },
                child: Icon(
                  CupertinoIcons.doc_on_doc,
                  size: 16,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
