import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/domain/models/sync_config.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/platform/webdav_sync_service.dart';

class WebDAVSettingsPage extends ConsumerStatefulWidget {
  const WebDAVSettingsPage({super.key});

  @override
  ConsumerState<WebDAVSettingsPage> createState() => _WebDAVSettingsPageState();
}

class _WebDAVSettingsPageState extends ConsumerState<WebDAVSettingsPage> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController(text: 'Hedge/vault.db');

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    final config = ref.read(vaultProvider).webdavConfig;
    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _remotePathController.text = config.remotePath;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_serverUrlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '请填写所有必填字段';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = WebDAVSyncService();
      await service.initialize(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        remotePath: _remotePathController.text.trim(),
      );

      setState(() {
        _successMessage = '连接成功！';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '连接失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndEnable() async {
    if (_serverUrlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '请填写所有必填字段';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = WebDAVConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        remotePath: _remotePathController.text.trim(),
      );

      await ref.read(vaultProvider.notifier).setSyncMode(
            SyncMode.webdav,
            webdavConfig: config,
          );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // 返回到设置页面
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败: $e';
        _isLoading = false;
      });
    }
  }

  void _useTemplate(String template) {
    switch (template) {
      case 'jianguoyun':
        _serverUrlController.text = 'https://dav.jianguoyun.com/dav/';
        _remotePathController.text = 'Hedge/vault.db';
        break;
      case 'nextcloud':
        _serverUrlController.text =
            'https://your-nextcloud.com/remote.php/dav/files/username/';
        _remotePathController.text = 'Hedge/vault.db';
        break;
      case 'synology':
        _serverUrlController.text = 'https://your-nas-ip:5006/';
        _remotePathController.text = 'Hedge/vault.db';
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('WebDAV 配置'),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 快速配置模板
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3C3C3E)
                      : CupertinoColors.systemGrey5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速配置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTemplateChip('坚果云', () => _useTemplate('jianguoyun'), isDark),
                      _buildTemplateChip('Nextcloud', () => _useTemplate('nextcloud'), isDark),
                      _buildTemplateChip('Synology', () => _useTemplate('synology'), isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 服务器配置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3C3C3E)
                      : CupertinoColors.systemGrey5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: '服务器地址',
                    controller: _serverUrlController,
                    placeholder: 'https://your-server.com/webdav',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '用户名',
                    controller: _usernameController,
                    placeholder: '用户名',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '密码',
                    controller: _passwordController,
                    placeholder: '密码或应用密码',
                    obscureText: _obscurePassword,
                    isDark: isDark,
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.only(right: 8),
                      minSize: 0,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 18,
                        color: isDark
                            ? CupertinoColors.white.withOpacity(0.6)
                            : CupertinoColors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '远程路径',
                    controller: _remotePathController,
                    placeholder: 'Hedge/vault.db',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 错误/成功消息
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.xmark_circle,
                        color: CupertinoColors.systemRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle,
                        color: CupertinoColors.systemGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null || _successMessage != null)
              const SizedBox(height: 16),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _isLoading ? null : _testConnection,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : Text(
                            '测试连接',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _isLoading ? null : _saveAndEnable,
                    child: const Text(
                      '保存并启用',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isDark,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? CupertinoColors.white.withOpacity(0.6)
                : CupertinoColors.black.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffix: suffix,
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.activeBlue.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ),
    );
  }
}
