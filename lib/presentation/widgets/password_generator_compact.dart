import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/password_generator_provider.dart';
import 'package:hedge/domain/models/password_strength.dart';

/// 极简密码生成器组件 - 用于快捷面板
class PasswordGeneratorCompact extends ConsumerWidget {
  const PasswordGeneratorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(passwordGeneratorProvider);

    return asyncState.when(
      data: (state) => _buildContent(context, ref, l10n, state),
      loading: () => const Center(
        child: CupertinoActivityIndicator(),
      ),
      error: (error, stack) => _buildErrorView(context, ref, l10n, error),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield,
                size: 16,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.passwordGenerator,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 密码显示（包含强度色块、刷新按钮、复制按钮）
          _buildPasswordDisplay(context, ref, l10n, state),

          const SizedBox(height: 10),

          // 长度滑块
          _buildLengthSlider(context, ref, l10n, state.config.length),
        ],
      ),
    );
  }

  Widget _buildPasswordDisplay(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // 密码文本
          Expanded(
            child: Text(
              state.generatedPassword,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 强度色块
          _buildStrengthBadge(state.strength),

          const SizedBox(width: 6),

          // 刷新按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(passwordGeneratorProvider.notifier).regenerate();
            },
            child: Icon(
              CupertinoIcons.arrow_clockwise,
              size: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),

          const SizedBox(width: 6),

          // 复制按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(
                ClipboardData(text: state.generatedPassword),
              );
              _showCopiedFeedback(context, l10n);
            },
            child: Icon(
              CupertinoIcons.doc_on_clipboard,
              size: 16,
              color: CupertinoColors.activeBlue.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建强度色块（1个汉字）
  Widget _buildStrengthBadge(PasswordStrength strength) {
    String label;
    switch (strength.level) {
      case StrengthLevel.weak:
        label = '低';
        break;
      case StrengthLevel.medium:
        label = '中';
        break;
      case StrengthLevel.strong:
        label = '高';
        break;
      case StrengthLevel.veryStrong:
        label = '强';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: strength.color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildLengthSlider(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int length,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.passwordLength,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$length',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CupertinoSlider(
          value: length.toDouble(),
          min: 8,
          max: 64,
          divisions: 56,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            final notifier = ref.read(passwordGeneratorProvider.notifier);
            final currentConfig = ref.read(passwordGeneratorProvider).value!.config;
            notifier.updateConfig(
              currentConfig.copyWith(length: value.toInt()),
            );
          },
        ),
      ],
    );
  }

  void _showCopiedFeedback(BuildContext context, AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.activeGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.copied(l10n.password),
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 自动关闭
    Future.delayed(const Duration(milliseconds: 800), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 32,
            color: CupertinoColors.systemRed.resolveFrom(context),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.error,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorMessage(error, l10n),
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(8),
            onPressed: () {
              ref.read(passwordGeneratorProvider.notifier).regenerate();
            },
            child: Text(
              l10n.retry,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(Object error, AppLocalizations l10n) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    return error.toString();
  }
}
