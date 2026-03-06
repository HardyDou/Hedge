import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/password_generator_provider.dart';
import 'password_display_widget.dart';
import 'password_strength_indicator.dart';
import 'password_generator_config_widget.dart';

/// 密码生成器底部面板（移动端）
class PasswordGeneratorSheet extends ConsumerWidget {
  final Function(String)? onPasswordSelected;

  const PasswordGeneratorSheet({
    super.key,
    this.onPasswordSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final generatorState = ref.watch(passwordGeneratorProvider);

    return generatorState.when(
      data: (state) => _buildContent(context, ref, l10n, state),
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => Center(
        child: Text('${l10n.error}: $error'),
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
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖动条
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.passwordGenerator,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 生成的密码
                    PasswordDisplayWidget(
                      password: state.generatedPassword,
                      onCopy: () {
                        HapticFeedback.lightImpact();
                      },
                    ),
                    const SizedBox(height: 16),
                    // 强度指示条
                    PasswordStrengthIndicator(
                      strength: state.strength,
                      showLabel: true,
                      showSuggestion: true,
                    ),
                    const SizedBox(height: 24),
                    // 分隔线
                    Container(
                      height: 1,
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                    ),
                    const SizedBox(height: 24),
                    // 配置选项
                    PasswordGeneratorConfigWidget(
                      config: state.config,
                      onConfigChanged: (newConfig) {
                        ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
                      },
                    ),
                    const SizedBox(height: 24),
                    // 分隔线
                    Container(
                      height: 1,
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                    ),
                    const SizedBox(height: 16),
                    // 按钮区域
                    Row(
                      children: [
                        // 重新生成按钮
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: CupertinoColors.systemGrey5.resolveFrom(context),
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(passwordGeneratorProvider.notifier).regenerate();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.refresh,
                                  size: 20,
                                  color: CupertinoColors.activeBlue.resolveFrom(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.regenerate,
                                  style: TextStyle(
                                    color: CupertinoColors.activeBlue.resolveFrom(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 使用此密码按钮
                        Expanded(
                          flex: 2,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (onPasswordSelected != null) {
                                onPasswordSelected!(state.generatedPassword);
                              }
                              Navigator.of(context).pop(state.generatedPassword);
                            },
                            child: Text(
                              l10n.useThisPassword,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示密码生成器面板
  static Future<String?> show(
    BuildContext context, {
    Function(String)? onPasswordSelected,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => PasswordGeneratorSheet(
        onPasswordSelected: onPasswordSelected,
      ),
    );
  }
}
