import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';

class AddItemPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(VaultItem) onSave;

  const AddItemPanel({super.key, required this.onClose, required this.onSave});

  @override
  ConsumerState<AddItemPanel> createState() => _AddItemPanelState();
}

class _AddItemPanelState extends ConsumerState<AddItemPanel> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      color: isDark ? CupertinoColors.black : const Color(0xFFF2F2F7),
      child: Column(
        children: [
          _buildHeader(isDark, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('标题', _titleController, isDark, placeholder: '必填'),
                  const SizedBox(height: 16),
                  _buildTextField('用户名', _usernameController, isDark),
                  const SizedBox(height: 16),
                  _buildTextField('密码', _passwordController, isDark, isPassword: true),
                  const SizedBox(height: 16),
                  _buildTextField('网址', _urlController, isDark, placeholder: 'https://'),
                  const SizedBox(height: 16),
                  _buildTextField('备注', _notesController, isDark, maxLines: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.1) : CupertinoColors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onClose,
            child: Text('取消', style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 16)),
          ),
          const Spacer(),
          Text('新建密码', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : Text('保存', style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {bool isPassword = false, int maxLines = 1, String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          placeholder: placeholder,
          style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
          placeholderStyle: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3)),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.black.withValues(alpha: 0.1)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) {
      _showError('请输入标题');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        url: _urlController.text.isNotEmpty ? _urlController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(vaultProvider.notifier).addItemWithDetails(newItem);
      widget.onSave(newItem);
    } catch (e) {
      _showError('保存失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(content: Text(message)),
    );
  }
}
