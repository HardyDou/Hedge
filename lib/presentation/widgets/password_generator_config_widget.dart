import 'package:flutter/cupertino.dart';
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
        // 长度控制
        _buildLengthControl(context, l10n),
        const SizedBox(height: 16),
        // 字符类型选项
        _buildCharacterTypeOptions(context, l10n),
        const SizedBox(height: 12),
        // 排除易混淆字符
        _buildExcludeAmbiguousOption(context, l10n),
      ],
    );
  }

  Widget _buildLengthControl(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          '${l10n.passwordLength}: ${config.length}',
          style: const TextStyle(fontSize: 16),
        ),
        const Spacer(),
        // 减少按钮
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: config.length > 8
              ? () {
                  onConfigChanged(config.copyWith(length: config.length - 1));
                }
              : null,
          child: const Icon(CupertinoIcons.minus_circle, size: 28),
        ),
        const SizedBox(width: 8),
        // 显示当前长度
        SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '${config.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 增加按钮
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: config.length < 64
              ? () {
                  onConfigChanged(config.copyWith(length: config.length + 1));
                }
              : null,
          child: const Icon(CupertinoIcons.plus_circle, size: 28),
        ),
      ],
    );
  }

  Widget _buildCharacterTypeOptions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildCheckboxRow(
          context,
          l10n.includeUppercase,
          config.includeUppercase,
          (value) => onConfigChanged(config.copyWith(includeUppercase: value)),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow(
          context,
          l10n.includeLowercase,
          config.includeLowercase,
          (value) => onConfigChanged(config.copyWith(includeLowercase: value)),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow(
          context,
          l10n.includeNumbers,
          config.includeNumbers,
          (value) => onConfigChanged(config.copyWith(includeNumbers: value)),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow(
          context,
          l10n.includeSymbols,
          config.includeSymbols,
          (value) => onConfigChanged(config.copyWith(includeSymbols: value)),
        ),
      ],
    );
  }

  Widget _buildExcludeAmbiguousOption(BuildContext context, AppLocalizations l10n) {
    return _buildCheckboxRow(
      context,
      '${l10n.excludeAmbiguous} (${l10n.excludeAmbiguousHint})',
      config.excludeAmbiguous,
      (value) => onConfigChanged(config.copyWith(excludeAmbiguous: value)),
    );
  }

  Widget _buildCheckboxRow(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          CupertinoCheckbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
