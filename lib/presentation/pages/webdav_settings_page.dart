import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

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
    if (!_formKey.currentState!.validate()) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV 同步已启用')),
        );
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
        _serverUrlController.text = 'https://your-nextcloud.com/remote.php/dav/files/username/';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 同步设置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 配置模板
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快速配置模板',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('坚果云'),
                          onPressed: () => _useTemplate('jianguoyun'),
                        ),
                        ActionChip(
                          label: const Text('Nextcloud'),
                          onPressed: () => _useTemplate('nextcloud'),
                        ),
                        ActionChip(
                          label: const Text('Synology NAS'),
                          onPressed: () => _useTemplate('synology'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 服务器地址
            TextFormField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'https://your-server.com/webdav',
                border: OutlineInputBorder(),
                helperText: '完整的 WebDAV 服务器 URL',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务器地址';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return '请输入有效的 URL（以 http:// 或 https:// 开头）';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 用户名
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 密码
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                helperText: '坚果云请使用应用密码',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 远程路径
            TextFormField(
              controller: _remotePathController,
              decoration: const InputDecoration(
                labelText: '远程路径',
                border: OutlineInputBorder(),
                helperText: '服务器上的文件路径',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入远程路径';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 错误/成功消息
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_successMessage != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 测试连接按钮
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: const Text('测试连接'),
            ),

            const SizedBox(height: 8),

            // 保存并启用按钮
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveAndEnable,
              icon: const Icon(Icons.save),
              label: const Text('保存并启用'),
            ),

            const SizedBox(height: 24),

            // 帮助信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '配置说明',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('坚果云配置步骤：'),
                    const Text('1. 登录坚果云网页版'),
                    const Text('2. 进入"账户信息 > 安全选项 > 第三方应用管理"'),
                    const Text('3. 添加应用，生成应用密码'),
                    const Text('4. 使用应用密码（不是登录密码）'),
                    const SizedBox(height: 12),
                    const Text('支持的服务：'),
                    const Text('• Nextcloud（自建，推荐）'),
                    const Text('• Synology NAS（自建，推荐）'),
                    const Text('• 坚果云（云服务，1GB 免费）'),
                    const Text('• ownCloud（自建）'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
