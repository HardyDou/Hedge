import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/password_generator_provider.dart';
import 'package:hedge/domain/models/password_generator_config.dart';
import 'package:hedge/domain/models/password_strength.dart';

/// 桌面端密码生成器 Popover — 重新设计版
/// 设计语言：扁平工具感，密码主导，配置内联，无多余容器
class PasswordGeneratorPopover extends ConsumerStatefulWidget {
  final Function(String)? onPasswordSelected;

  const PasswordGeneratorPopover({super.key, this.onPasswordSelected});

  static Future<String?> show(
    BuildContext context, {
    Offset? position,
    Function(String)? onPasswordSelected,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => PasswordGeneratorPopover(
        onPasswordSelected: onPasswordSelected,
      ),
    );
  }

  @override
  ConsumerState<PasswordGeneratorPopover> createState() =>
      _PasswordGeneratorPopoverState();
}

class _PasswordGeneratorPopoverState
    extends ConsumerState<PasswordGeneratorPopover> {
  bool _copied = false;

  Future<void> _copyPassword(String password) async {
    await Clipboard.setData(ClipboardData(text: password));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(passwordGeneratorProvider);
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: Container(
        width: (screenSize.width * 0.85).clamp(0.0, 380.0),
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.12),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: asyncState.when(
            data: (state) => _buildContent(context, l10n, state),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  '${l10n.error}: $e',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    PasswordGeneratorState state,
  ) {
    final config = state.config;
    final includeNumbers = config.includeNumbers == true;
    final includeSymbols = config.includeSymbols == true;
    final excludeAmbiguous = config.excludeAmbiguous == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 密码主区域 ──────────────────────────────────────
        _PasswordHero(
          password: state.generatedPassword,
          strength: state.strength,
          copied: _copied,
          onRegenerate: () {
            HapticFeedback.lightImpact();
            ref.read(passwordGeneratorProvider.notifier).regenerate();
          },
          onCopy: () => _copyPassword(state.generatedPassword),
        ),

        // ── 配置区 ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            children: [
              // 长度行
              _LengthRow(
                config: config,
                l10n: l10n,
                onChanged: (v) => ref
                    .read(passwordGeneratorProvider.notifier)
                    .updateConfig(config.copyWith(length: v)),
              ),
              const SizedBox(height: 2),
              _separator(context),
              const SizedBox(height: 2),
              // 数字 + 符号 合并一行
              _DoubleToggleRow(
                leftLabel: '数字',
                leftValue: includeNumbers,
                onLeftChanged: (v) => ref
                    .read(passwordGeneratorProvider.notifier)
                    .updateConfig(config.copyWith(includeNumbers: v)),
                rightLabel: '符号',
                rightValue: includeSymbols,
                onRightChanged: (v) => ref
                    .read(passwordGeneratorProvider.notifier)
                    .updateConfig(config.copyWith(includeSymbols: v)),
              ),
              _ToggleRow(
                label: l10n.excludeAmbiguous,
                value: excludeAmbiguous,
                hint: '0 O 1 l I',
                onChanged: (v) => ref
                    .read(passwordGeneratorProvider.notifier)
                    .updateConfig(config.copyWith(excludeAmbiguous: v)),
              ),
            ],
          ),
        ),

        // ── 底部操作 ─────────────────────────────────────────
        _Footer(
          l10n: l10n,
          password: state.generatedPassword,
          onPasswordSelected: widget.onPasswordSelected,
        ),
      ],
    );
  }

  Widget _separator(BuildContext context) {
    return Container(
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 密码主展示区
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordHero extends StatelessWidget {
  final String password;
  final PasswordStrength strength;
  final bool copied;
  final VoidCallback onRegenerate;
  final VoidCallback onCopy;

  const _PasswordHero({
    required this.password,
    required this.strength,
    required this.copied,
    required this.onRegenerate,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                size: 15,
                color: CupertinoColors.activeBlue.resolveFrom(context),
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.passwordGenerator,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 28,
                onPressed: () => Navigator.of(context).pop(),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 密码文本
          Text(
            password,
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              height: 1.5,
              color: CupertinoColors.label.resolveFrom(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // 强度 + 操作行
          Row(
            children: [
              // 四段强度色块
              _StrengthSegments(strength: strength),
              const SizedBox(width: 8),
              Text(
                _strengthLabel(strength.level),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strength.color,
                ),
              ),
              const Spacer(),
              // 刷新
              _IconBtn(
                icon: CupertinoIcons.arrow_clockwise,
                onTap: onRegenerate,
                color: CupertinoColors.activeBlue.resolveFrom(context),
              ),
              const SizedBox(width: 4),
              // 复制（带反馈）
              _CopyBtn(copied: copied, onTap: onCopy),
            ],
          ),
        ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// 四段强度色块
// ─────────────────────────────────────────────────────────────────────────────

class _StrengthSegments extends StatelessWidget {
  final PasswordStrength strength;

  const _StrengthSegments({required this.strength});

  @override
  Widget build(BuildContext context) {
    final filled = _filledCount(strength.level);
    final activeColor = strength.color;
    final trackColor = CupertinoColors.systemGrey5.resolveFrom(context);

    return Row(
      children: List.generate(4, (i) {
        return Container(
          width: 20,
          height: 4,
          margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
          decoration: BoxDecoration(
            color: i < filled ? activeColor : trackColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  int _filledCount(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.weak:
        return 1;
      case StrengthLevel.medium:
        return 2;
      case StrengthLevel.strong:
        return 3;
      case StrengthLevel.veryStrong:
        return 4;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 图标按钮
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(6),
      minSize: 32,
      onPressed: onTap,
      child: Icon(icon, size: 17, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 复制按钮（带已复制状态）
// ─────────────────────────────────────────────────────────────────────────────

class _CopyBtn extends StatelessWidget {
  final bool copied;
  final VoidCallback onTap;

  const _CopyBtn({required this.copied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minSize: 32,
      onPressed: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: copied
            ? Row(
                key: const ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark,
                    size: 13,
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已复制',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGreen.resolveFrom(context),
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('copy'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '复制',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 长度行（滑块 + 数值）
// ─────────────────────────────────────────────────────────────────────────────

class _LengthRow extends StatelessWidget {
  final PasswordGeneratorConfig config;
  final AppLocalizations l10n;
  final ValueChanged<int> onChanged;

  const _LengthRow({
    required this.config,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            l10n.passwordLength,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: '${l10n.passwordLength}: ${config.length}',
              value: '${config.length}',
              child: CupertinoSlider(
                value: config.length.toDouble(),
                min: 8,
                max: 64,
                divisions: 56,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v.toInt());
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${config.length}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue.resolveFrom(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 双开关行（数字 + 符号 并排）
// ─────────────────────────────────────────────────────────────────────────────

class _DoubleToggleRow extends StatelessWidget {
  final String leftLabel;
  final bool leftValue;
  final ValueChanged<bool> onLeftChanged;
  final String rightLabel;
  final bool rightValue;
  final ValueChanged<bool> onRightChanged;

  const _DoubleToggleRow({
    required this.leftLabel,
    required this.leftValue,
    required this.onLeftChanged,
    required this.rightLabel,
    required this.rightValue,
    required this.onRightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          _chip(context, leftLabel, leftValue, onLeftChanged),
          const SizedBox(width: 8),
          _chip(context, rightLabel, rightValue, onRightChanged),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final activeColor = CupertinoColors.activeBlue.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final inactiveColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFE5E5EA);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.12) : inactiveColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? activeColor.withOpacity(0.4) : inactiveColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                value ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                key: ValueKey(value),
                size: 14,
                color: value
                    ? activeColor
                    : CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                color: value
                    ? activeColor
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 开关行
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final String? hint;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                fontFamily: 'Menlo',
              ),
            ),
          ],
          const Spacer(),
          CupertinoSwitch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 底部操作栏
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final AppLocalizations l10n;
  final String password;
  final Function(String)? onPasswordSelected;

  const _Footer({
    required this.l10n,
    required this.password,
    required this.onPasswordSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPasswordSelected?.call(password);
                Navigator.of(context).pop(password);
              },
              child: Text(
                l10n.useThisPassword,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
