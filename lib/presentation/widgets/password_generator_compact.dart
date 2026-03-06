import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/password_generator_provider.dart';

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

          // 密码显示
          _buildPasswordDisplay(context, ref, state.generatedPassword),

          const SizedBox(height: 10),

          // 快捷操作按钮
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(6),
                  minSize: 0,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(passwordGeneratorProvider.notifier).regenerate();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 14,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.regenerate,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(6),
                  minSize: 0,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Clipboard.setData(
                      ClipboardData(text: state.generatedPassword),
                    );
                    // 显示提示
                    _showCopiedFeedback(context, l10n);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.doc_on_clipboard,
                        size: 14,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.copy,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 长度调整
          _buildLengthControl(context, ref, l10n, state.config.length),
        ],
      ),
    );
  }

  Widget _buildPasswordDisplay(
    BuildContext context,
    WidgetRef ref,
    String password,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        password,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Courier',
          fontWeight: FontWeight.w500,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLengthControl(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int length,
  ) {
    return Row(
      children: [
        Text(
          l10n.passwordLength,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: length > 8
              ? () {
                  final notifier = ref.read(passwordGeneratorProvider.notifier);
                  final currentConfig = ref.read(passwordGeneratorProvider).value!.config;
                  notifier.updateConfig(
                    currentConfig.copyWith(length: length - 1),
                  );
                }
              : null,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: length > 8
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              CupertinoIcons.minus,
              size: 14,
              color: length > 8
                  ? CupertinoColors.label.resolveFrom(context)
                  : CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '$length',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: length < 64
              ? () {
                  final notifier = ref.read(passwordGeneratorProvider.notifier);
                  final currentConfig = ref.read(passwordGeneratorProvider).value!.config;
                  notifier.updateConfig(
                    currentConfig.copyWith(length: length + 1),
                  );
                }
              : null,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: length < 64
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              CupertinoIcons.plus,
              size: 14,
              color: length < 64
                  ? CupertinoColors.label.resolveFrom(context)
                  : CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
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
