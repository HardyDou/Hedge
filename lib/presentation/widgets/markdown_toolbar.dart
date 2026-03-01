import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isPreview;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.isDark,
    this.isPreview = false,
  });

  void _wrapSelection(String before, String after, {String placeholder = ''}) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    final selected = sel.isCollapsed ? placeholder : sel.textInside(text);
    final newText = text.replaceRange(sel.start, sel.end, '$before$selected$after');
    final newStart = sel.start + before.length;
    final newEnd = newStart + selected.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
    );
  }

  void _insertLinePrefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    final offset = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + prefix.length),
    );
  }

  void _insertDivider() {
    final text = controller.text;
    final sel = controller.selection;
    final offset = sel.isValid ? sel.start : text.length;
    final needsNewline = offset > 0 && text[offset - 1] != '\n';
    final insert = '${needsNewline ? '\n' : ''}---\n';
    final newText = text.replaceRange(offset, sel.isValid ? sel.end : offset, insert);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + insert.length),
    );
  }

  void _insertCodeBlock() {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    final selected = sel.isCollapsed ? '' : sel.textInside(text);
    final inner = selected.isEmpty ? '\n' : '\n$selected\n';
    final block = '```$inner```';
    final newText = text.replaceRange(sel.start, sel.end, block);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: sel.start + (selected.isEmpty ? 4 : block.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.1)
        : CupertinoColors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _ToolbarTextButton(label: 'B', isDark: isDark, isDisabled: isPreview, onTap: () => _wrapSelection('**', '**', placeholder: 'bold')),
          _ToolbarTextButton(label: 'I', isDark: isDark, isDisabled: isPreview, onTap: () => _wrapSelection('*', '*', placeholder: 'italic')),
          _ToolbarSep(isDark: isDark),
          _ToolbarTextButton(label: 'H1', isDark: isDark, isDisabled: isPreview, onTap: () => _insertLinePrefix('# ')),
          _ToolbarTextButton(label: 'H2', isDark: isDark, isDisabled: isPreview, onTap: () => _insertLinePrefix('## ')),
          _ToolbarSep(isDark: isDark),
          _ToolbarIconButton(icon: CupertinoIcons.list_bullet, isDark: isDark, isDisabled: isPreview, onTap: () => _insertLinePrefix('- ')),
          _ToolbarIconButton(icon: CupertinoIcons.minus, isDark: isDark, isDisabled: isPreview, onTap: _insertDivider),
          _ToolbarIconButton(icon: CupertinoIcons.chevron_left_slash_chevron_right, isDark: isDark, isDisabled: isPreview, onTap: _insertCodeBlock),
        ],
      ),
    );
  }
}

class _ToolbarTextButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isDisabled;
  final VoidCallback onTap;
  const _ToolbarTextButton({required this.label, required this.isDark, this.isDisabled = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minSize: 36,
      onPressed: isDisabled ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Text(
        label,
        style: TextStyle(
          color: isDisabled
              ? (isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3))
              : (isDark ? CupertinoColors.white : CupertinoColors.black),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isDisabled;
  final VoidCallback onTap;
  const _ToolbarIconButton({required this.icon, required this.isDark, this.isDisabled = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minSize: 36,
      onPressed: isDisabled ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Icon(
        icon,
        size: 18,
        color: isDisabled
            ? (isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3))
            : (isDark
                ? CupertinoColors.white.withValues(alpha: 0.85)
                : CupertinoColors.black.withValues(alpha: 0.7)),
      ),
    );
  }
}

class _ToolbarSep extends StatelessWidget {
  final bool isDark;
  const _ToolbarSep({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark
          ? CupertinoColors.white.withValues(alpha: 0.2)
          : CupertinoColors.black.withValues(alpha: 0.15),
    );
  }
}
