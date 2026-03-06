import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/models/password_generator_config.dart';

/// 密码生成器配置选项组件
class PasswordGeneratorConfigWidget extends StatelessWidget {
  final PasswordGeneratorConfig config;
  final ValueChanged<PasswordGeneratorConfig> onConfigChanged;

  const PasswordGeneratorConfigWidget({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 长度滑块
        _buildSlider(
          context,
          l10n.passwordLength,
          config.length,
          8,
          64,
          (value) => onConfigChanged(config.copyWith(length: value)),
        ),
        const SizedBox(height: 16),
        // 数字数量滑块
        _buildSlider(
          context,
          '数字',
          config.numbersCount,
          0,
          config.length,
          (value) => onConfigChanged(config.copyWith(numbersCount: value)),
        ),
        const SizedBox(height: 16),
        // 符号数量滑块
        _buildSlider(
          context,
          '符号',
          config.symbolsCount,
          0,
          config.length,
          (value) => onConfigChanged(config.copyWith(symbolsCount: value)),
        ),
        const SizedBox(height: 12),
        // 排除易混淆字符
        _buildExcludeAmbiguousOption(context, l10n),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (newValue) {
            HapticFeedback.selectionClick();
            onChanged(newValue.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildExcludeAmbiguousOption(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onConfigChanged(config.copyWith(excludeAmbiguous: !config.excludeAmbiguous));
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          CupertinoCheckbox(
            value: config.excludeAmbiguous,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onConfigChanged(config.copyWith(excludeAmbiguous: value ?? false));
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.excludeAmbiguous} (${l10n.excludeAmbiguousHint})',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
