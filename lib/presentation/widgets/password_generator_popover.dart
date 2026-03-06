import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/password_generator_provider.dart';
import 'package:hedge/presentation/widgets/password_display_widget.dart';
import 'package:hedge/presentation/widgets/password_strength_indicator.dart';
import 'package:hedge/domain/models/password_generator_config.dart';

/// 桌面端密码生成器 Popover 浮层组件
class PasswordGeneratorPopover extends ConsumerWidget {
  final Function(String)? onPasswordSelected;

  const PasswordGeneratorPopover({
    super.key,
    this.onPasswordSelected,
  });

  /// 显示 Popover
  static Future<String?> show(
    BuildContext context, {
    Offset? position,
  }) async {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => const PasswordGeneratorPopover(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(passwordGeneratorProvider);

    return Center(
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: asyncState.when(
          data: (state) => _buildContent(context, ref, l10n, state),
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        _buildHeader(context, l10n),

        Container(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),

        // 内容区域
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 密码显示
                PasswordDisplayWidget(
                  password: state.generatedPassword,
                ),

                const SizedBox(height: 8),

                // 重新生成按钮
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(passwordGeneratorProvider.notifier).regenerate();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.regenerate),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 强度指示器
                PasswordStrengthIndicator(strength: state.strength),

                const SizedBox(height: 24),

                // 配置选项 - 桌面端布局
                _buildDesktopConfig(context, ref, l10n, state.config),
              ],
            ),
          ),
        ),

        Container(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),

        // 底部按钮
        _buildFooter(context, ref, l10n, state.generatedPassword),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.lock_shield,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.passwordGenerator,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopConfig(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 长度滑块
        _buildLengthSlider(context, ref, l10n, config),

        const SizedBox(height: 24),

        // 字符类型选项 - 双列布局
        Text(
          l10n.passwordLength,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildCharacterOptions(context, ref, l10n, config),

        const SizedBox(height: 16),

        // 排除易混淆字符
        _buildExcludeAmbiguousOption(context, ref, l10n, config),
      ],
    );
  }

  Widget _buildLengthSlider(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.passwordLength,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${config.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: config.length.toDouble(),
          min: 8,
          max: 64,
          divisions: 56,
          onChanged: (value) {
            final newConfig = config.copyWith(length: value.toInt());
            ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '8',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
            Text(
              '64',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCheckbox(
                context,
                ref,
                'A-Z',
                config.includeUppercase,
                (value) {
                  final newConfig = config.copyWith(includeUppercase: value);
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCheckbox(
                context,
                ref,
                'a-z',
                config.includeLowercase,
                (value) {
                  final newConfig = config.copyWith(includeLowercase: value);
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCheckbox(
                context,
                ref,
                '0-9',
                config.includeNumbers,
                (value) {
                  final newConfig = config.copyWith(includeNumbers: value);
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCheckbox(
                context,
                ref,
                r'!@#$',
                config.includeSymbols,
                (value) {
                  final newConfig = config.copyWith(includeSymbols: value);
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? CupertinoColors.activeBlue.withOpacity(0.1)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4.resolveFrom(context),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              color: value ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  color: value ? CupertinoColors.activeBlue : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcludeAmbiguousOption(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return GestureDetector(
      onTap: () {
        final newConfig = config.copyWith(excludeAmbiguous: !config.excludeAmbiguous);
        ref.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              config.excludeAmbiguous
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: config.excludeAmbiguous
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.excludeAmbiguous,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String password,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: CupertinoColors.systemGrey5,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: CupertinoColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: CupertinoColors.activeBlue,
              onPressed: () {
                Navigator.of(context).pop(password);
              },
              child: Text(
                l10n.use,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
