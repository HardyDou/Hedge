import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/password_generator_provider.dart';
import '../../domain/models/password_generator_config.dart';
import '../../domain/models/password_strength.dart';

/// 密码生成器底部面板（移动端）
/// 设计原则：拇指可达、触控目标充足、信息层级清晰
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
      loading: () => const SizedBox(
        height: 320,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '${l10n.error}: $error',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 14,
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动条
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题栏
            _buildHeader(context, ref, l10n),
            // 可滚动内容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 密码展示卡片
                    _buildPasswordCard(context, ref, l10n, state),
                    const SizedBox(height: 24),
                    // 配置区
                    _buildConfigSection(context, ref, l10n, state.config),
                    const SizedBox(height: 24),
                    // 主操作按钮
                    _buildUseButton(context, ref, l10n, state.generatedPassword),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          Text(
            l10n.passwordGenerator,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            minSize: 44,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 密码文本
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              state.generatedPassword,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                height: 1.4,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 强度进度条
          _buildStrengthBar(context, state.strength),
          // 操作按钮行
          _buildPasswordActions(context, ref, l10n, state.generatedPassword),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(BuildContext context, PasswordStrength strength) {
    final label = _strengthLabel(strength.level);
    final color = strength.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                    ),
                    FractionallySizedBox(
                      widthFactor: strength.progress,
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String password,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 重新生成
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(passwordGeneratorProvider.notifier).regenerate();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 16,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.regenerate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 分隔线
          Container(
            width: 0.5,
            height: 44,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          // 复制
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: password));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 16,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.copy,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 长度 — stepper
          _buildLengthRow(context, ref, l10n, config),
          _buildDivider(context),
          // 数字 — 滑块
          _buildSliderRow(
            context,
            label: '数字',
            value: config.numbersCount,
            min: 0,
            max: config.length - config.symbolsCount,
            onChanged: (v) {
              ref.read(passwordGeneratorProvider.notifier).updateConfig(
                    config.copyWith(numbersCount: v),
                  );
            },
          ),
          _buildDivider(context),
          // 符号 — 滑块
          _buildSliderRow(
            context,
            label: '符号',
            value: config.symbolsCount,
            min: 0,
            max: config.length - config.numbersCount,
            onChanged: (v) {
              ref.read(passwordGeneratorProvider.notifier).updateConfig(
                    config.copyWith(symbolsCount: v),
                  );
            },
          ),
          _buildDivider(context),
          // 排除易混淆 — switch
          _buildSwitchRow(context, ref, l10n, config),
        ],
      ),
    );
  }

  Widget _buildLengthRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            l10n.passwordLength,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const Spacer(),
          // Stepper: − 数字 +
          Row(
            children: [
              _buildStepperButton(
                context: context,
                icon: CupertinoIcons.minus,
                enabled: config.length > 8,
                onTap: () {
                  if (config.length <= 8) return;
                  HapticFeedback.selectionClick();
                  final newLength = config.length - 1;
                  final numbers = config.numbersCount.clamp(0, newLength);
                  final symbols = config.symbolsCount.clamp(0, newLength - numbers);
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(
                        config.copyWith(
                          length: newLength,
                          numbersCount: numbers,
                          symbolsCount: symbols,
                        ),
                      );
                },
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${config.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                ),
              ),
              _buildStepperButton(
                context: context,
                icon: CupertinoIcons.plus,
                enabled: config.length < 64,
                onTap: () {
                  if (config.length >= 64) return;
                  HapticFeedback.selectionClick();
                  ref.read(passwordGeneratorProvider.notifier).updateConfig(
                        config.copyWith(length: config.length + 1),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required BuildContext context,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? CupertinoColors.systemGrey5.resolveFrom(context)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? CupertinoColors.activeBlue.resolveFrom(context)
              : CupertinoColors.systemGrey3.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    // 确保 value 在 [min, max] 范围内
    final clampedValue = value.clamp(min, max);

    // 当 max == min 时，滑块无法渲染（会导致 division by zero），显示禁用状态
    final isDisabled = max <= min;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isDisabled
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '$clampedValue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          if (isDisabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '已达上限',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            )
          else
            Semantics(
              label: '$label: $clampedValue',
              value: '$clampedValue',
              increasedValue: '${clampedValue + 1}',
              decreasedValue: '${clampedValue - 1}',
              child: CupertinoSlider(
                value: clampedValue.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min).clamp(1, 64),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v.toInt());
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PasswordGeneratorConfig config,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.excludeAmbiguous,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.excludeAmbiguousHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: config.excludeAmbiguous,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              ref.read(passwordGeneratorProvider.notifier).updateConfig(
                    config.copyWith(excludeAmbiguous: v),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildUseButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String password,
  ) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: CupertinoColors.activeBlue,
      borderRadius: BorderRadius.circular(12),
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPasswordSelected?.call(password);
        Navigator.of(context).pop(password);
      },
      child: Text(
        l10n.useThisPassword,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  String _strengthLabel(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.weak:
        return '弱';
      case StrengthLevel.medium:
        return '一般';
      case StrengthLevel.strong:
        return '强';
      case StrengthLevel.veryStrong:
        return '极强';
    }
  }

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
