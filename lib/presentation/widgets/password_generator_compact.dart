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
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                CupertinoIcons.lock_shield,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.passwordGenerator,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 密码显示
          _buildPasswordDisplay(context, ref, state.generatedPassword),

          const SizedBox(height: 12),

          // 快捷操作按钮
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  onPressed: () {
                    ref.read(passwordGeneratorProvider.notifier).regenerate();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 16,
                        color: CupertinoColors.label,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.regenerate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: CupertinoColors.activeBlue,
                  onPressed: () {
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
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.copy,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        password,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Courier',
          fontWeight: FontWeight.w500,
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
          style: const TextStyle(fontSize: 13),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: length > 8
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              CupertinoIcons.minus,
              size: 16,
              color: length > 8
                  ? CupertinoColors.label.resolveFrom(context)
                  : CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$length',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: length < 64
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              CupertinoIcons.plus,
              size: 16,
              color: length < 64
                  ? CupertinoColors.label.resolveFrom(context)
                  : CupertinoColors.systemGrey3.resolveFrom(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
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
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.activeGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.copied(l10n.password),
                style: const TextStyle(fontSize: 15),
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
}
