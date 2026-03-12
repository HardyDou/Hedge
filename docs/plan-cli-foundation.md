# CLI Foundation - 产品规划与开发计划

**功能名称**: CLI Foundation with Biometric Authentication + WebDAV Sync
**目标版本**: v1.9.0
**优先级**: P0（必须完成，浏览器插件依赖）
**日期**: 2026-03-11
**文档状态**: 最终版本（已整合 Keychain 共享方案）

---

## 👤 用户画像

**李明** - 32岁，全栈开发者
- 每天需要登录 20+ 个服务（GitHub, AWS, 数据库等）
- 经常在终端工作，不想切换到 GUI 应用
- 使用自动化脚本部署应用，需要安全地获取凭证
- 希望 CLI 工具像 1Password CLI 一样流畅

---

## 📖 核心用户故事

### 故事 1：终端快速获取密码

**场景描述**：
李明在终端工作，需要登录 AWS 控制台。他不想打开 Hedge App，希望直接在终端获取密码。

**用户目标**：
在终端快速获取密码并复制到剪贴板。

**操作流程**：
```bash
# Desktop App 正在运行（生物识别模式）
$ hedge get aws
🔐 Authenticating via Desktop App (Touch ID)...
[Touch ID 提示弹出]
✓ Password copied to clipboard

# Desktop App 未运行（独立模式）
$ hedge get aws
⚠️  Desktop App not detected. Falling back to master password mode.
🔑 Enter master password: ********
✓ Password copied to clipboard
```

**时间成本**：约 5 秒

---

### 故事 2：自动化脚本获取凭证

**场景描述**：
李明写了一个部署脚本，需要自动获取数据库密码。脚本运行在 CI/CD 环境，没有 GUI。

**用户目标**：
脚本能够无交互地获取密码。

**操作流程**：
```bash
# 在 CI/CD 环境设置环境变量
export HEDGE_MASTER_PASSWORD="xxx"

# 脚本中使用
DB_PASSWORD=$(hedge get production-db --field password --no-app)
docker run -e DB_PASSWORD="$DB_PASSWORD" myapp
```

**时间成本**：约 1 秒

---

### 故事 3：列出所有密码条目

**场景描述**：
李明忘记了某个服务的确切名称，想快速浏览所有密码条目。

**用户目标**：
在终端列出所有密码，快速找到目标。

**操作流程**：
```bash
$ hedge list
🔐 Authenticating via Desktop App (Touch ID)...
[Touch ID 提示弹出]

Vault Items (23):
  • AWS Console
  • GitHub
  • GitLab
  • Google Account
  • Production Database
  ...
```

**时间成本**：约 3 秒

---

### 故事 4：搜索密码

**场景描述**：
李明有 100+ 个密码，想快速搜索包含 "github" 的条目。

**用户目标**：
模糊搜索密码条目。

**操作流程**：
```bash
$ hedge search github
🔐 Authenticating via Desktop App (Touch ID)...

Found 3 items:
  • GitHub Personal
  • GitHub Work
  • GitHub API Token
```

**时间成本**：约 3 秒

---

### 故事 5：手动锁定 CLI 会话

**场景描述**：
李明在公共场所工作，离开电脑前想手动锁定 CLI 会话。

**用户目标**：
立即清除 CLI 的会话令牌。

**操作流程**：
```bash
$ hedge lock
✓ CLI session locked. Next command will require authentication.
```

**时间成本**：约 1 秒

---

## 🎯 入口总结

### CLI 命令（MVP）
1. **`hedge get <item>`** - 获取密码（复制到剪贴板）
2. **`hedge list`** - 列出所有密码条目
3. **`hedge search <query>`** - 搜索密码条目
4. **`hedge lock`** - 锁定 CLI 会话
5. **`hedge unlock`** - 手动创建会话令牌
6. **`hedge sync`** - WebDAV 同步（新增）
7. **`hedge config`** - 配置管理（新增）
8. **`hedge --help`** - 显示帮助信息

### 认证模式
1. **生物识别模式** - CLI 通过 IPC 连接 Desktop App，使用 Touch ID/Face ID
2. **独立模式** - CLI 直接读取 vault 文件，使用主密码
3. **混合模式** - 自动检测 Desktop App，优先使用生物识别，降级到主密码

---

## 💡 设计亮点

### 1. 零配置
- CLI 自动检测 Desktop App 是否运行
- 无需手动配置 IPC 路径或认证模式
- 开箱即用

### 2. 安全优先 + 配置共享
- 会话令牌加密存储（`~/.hedge/cli-session.enc`）
- **WebDAV 配置自动共享**（从系统 Keychain 读取，与 Desktop App 共享）
- 短期过期（生物识别 15 分钟，主密码 5 分钟）
- IPC socket 权限限制（0600）
- 支持手动锁定（`hedge lock`）

### 3. 优雅降级
- Desktop App 未运行 → 主密码模式
- Desktop App 崩溃 → 主密码模式
- 生物识别失败 → 主密码模式
- 网络驱动器超时 → 错误提示

### 4. 开发者友好
- 支持管道操作（`hedge get aws | pbcopy`）
- 支持环境变量（`HEDGE_MASTER_PASSWORD`）
- 清晰的错误提示
- 详细的 `--help` 文档

---

## 🎯 核心需求

### 功能需求

**1. CLI 命令**
- `hedge get <item>` - 获取密码
  - 默认复制到剪贴板
  - `--field <field>` - 获取特定字段（username, password, url, notes）
  - `--no-copy` - 输出到 stdout 而不是剪贴板
- `hedge list` - 列出所有条目（仅标题）
- `hedge search <query>` - 搜索条目（支持标题、URL、用户名）
- `hedge lock` - 锁定 CLI 会话
- `hedge unlock` - 创建会话令牌（可选 `--output-token` 输出令牌）
- `hedge sync` - WebDAV 同步（新增）
  - `hedge sync` - 执行同步
  - `hedge sync --status` - 查看同步状态
  - `hedge sync --force-upload` - 强制上传（覆盖远程）
  - `hedge sync --force-download` - 强制下载（覆盖本地）
- `hedge config` - 配置管理（新增）
  - `hedge config show` - 查看当前配置
  - `hedge config webdav` - 配置 WebDAV
  - `hedge config delete` - 删除 CLI 配置
- `hedge --help` - 帮助信息
- `hedge --version` - 版本信息

**2. 认证模式**
- **生物识别模式**（优先）
  - CLI 通过 IPC 连接 Desktop App
  - Desktop App 弹出生物识别提示
  - 返回会话令牌（15 分钟有效）
- **独立模式**（降级）
  - CLI 提示输入主密码
  - 使用 Argon2id 派生密钥
  - 创建会话令牌（5 分钟有效）
- **混合模式**（自动）
  - 自动检测 Desktop App 是否运行
  - 优先使用生物识别，降级到主密码
  - `--no-app` 标志强制独立模式

**3. 会话管理**
- 会话令牌存储在加密文件 `~/.hedge/cli-session.enc`
- 使用 AES-256-GCM 加密，密钥从设备特征派生：`HMAC-SHA256(hostname + username + fixed-salt)`
- 文件权限：0600（仅所有者可读写）
- 令牌为不透明 UUID，由 Desktop App 维护会话注册表验证
- 过期时间：
  - 生物识别模式：15 分钟不活动
  - 独立模式：5 分钟不活动
  - Desktop App 锁定时立即失效（Desktop App 调用 `revokeAllSessions()`）
- 支持多个并发 CLI 进程（每个进程独立的令牌）
- CLI 启动时自动清理过期令牌

**WebDAV 配置共享**：
- Desktop App 使用 `flutter_secure_storage` 写入系统 Keychain
- CLI 使用系统命令读取 Keychain：
  - macOS: `security find-generic-password -s flutter_secure_storage.<key> -w`
  - Linux: `secret-tool lookup service flutter_secure_storage account <key>`
  - Windows: Credential Manager（v2.0 实现）
- 配置读取优先级：环境变量 > Keychain > CLI 配置文件 > IPC > 提示用户
- 无需重复配置，Desktop App 配置后 CLI 自动可用

**注**：由于 `dart compile exe` 限制，会话令牌无法使用系统 Keychain（需要 Flutter 插件），但 WebDAV 配置可以通过系统命令行工具读取 Keychain。加密文件存储安全性略低于 Keychain，但对于短期令牌（5-15 分钟）是可接受的。

**4. IPC 协议**
- 协议：JSON-RPC 2.0（自定义实现，长度前缀格式）
- 传输：Unix domain socket (macOS/Linux), Named pipe (Windows)
- Socket 路径：`/tmp/hedge-ipc-$UID.sock`（macOS/Linux 统一使用此路径）
- Socket 文件权限：0600（仅所有者可读写）
- **主要安全机制**：UID 验证（Desktop App 检查连接进程的 UID，拒绝其他用户）
- **超时策略**：CLI 端 5 秒超时，超时后降级到独立模式
- **Socket 清理**：Desktop App 启动时检查并删除陈旧的 socket 文件
- **协议格式**：长度前缀 JSON：`[4字节长度（网络字节序）][JSON payload]`
- 方法：
  - `get_version` - 获取 Desktop App 版本（用于兼容性检查）
  - `authenticate` - 请求生物识别认证
  - `get_password` - 获取密码
  - `list_items` - 列出条目
  - `lock_vault` - 锁定 vault
  - `ping` - 健康检查
  - `vault_status` - 检查 vault 状态
  - `revoke_token` - 撤销会话令牌
  - `get_webdav_config` - 获取 WebDAV 配置（新增）

**5. Desktop App IPC Server**
- 在主 isolate 运行（MVP 阶段，v2.0 考虑移到后台 isolate）
- 监听 IPC socket
- 验证连接进程的 UID
- 处理 CLI 请求
- 推送 "vault locked" 事件到所有连接的 CLI 客户端
- 可选功能（设置：Enable CLI Access，默认启用）
- 启动时清理陈旧的 socket 文件

---

## ⚙️ 技术方案

### 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    Hedge Desktop App                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Biometric Unlock → Vault Decryption → Session    │ │
│  └────────────────────────────────────────────────────┘ │
│                          ↓                               │
│  ┌────────────────────────────────────────────────────┐ │
│  │  IPC Server (Background Isolate)                   │ │
│  │  - Unix Socket / Named Pipe                        │ │
│  │  - JSON-RPC 2.0 Protocol                           │ │
│  │  - Session Token Validation                        │ │
│  │  - UID Validation                                  │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │ IPC (JSON-RPC)
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    hedge CLI Tool                        │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Dart Executable (dart compile exe)                │ │
│  │  - IPC Client (优先)                                │ │
│  │  - Direct Vault Access (降级)                       │ │
│  │  - Session Token Management                        │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   Terminal         CI/CD Scripts      Browser Ext
```

### 认证流程

**生物识别模式**：
```
1. CLI 检查 IPC socket 是否存在
2. CLI 连接到 Desktop App
3. CLI 发送 authenticate 请求
4. Desktop App 弹出生物识别提示
5. 用户完成 Touch ID/Face ID
6. Desktop App 返回会话令牌
7. CLI 加密存储令牌到 ~/.hedge/cli-session.enc
8. CLI 执行命令（get/list/search）
9. 后续命令复用会话令牌（15 分钟内）
```

**独立模式**：
```
1. CLI 检查 IPC socket（不存在或超时）
2. CLI 提示输入主密码
3. CLI 使用 Argon2id 派生密钥
4. CLI 解密 vault 文件
5. CLI 创建会话令牌（5 分钟有效）
6. CLI 执行命令
7. 后续命令复用会话令牌（5 分钟内）
```

### 代码结构与共享策略

**策略**：CLI 作为独立 Dart 包，通过相对路径导入主应用的纯 Dart 代码。

```
hedge/
├── lib/
│   ├── src/dart/                         # 纯 Dart 代码（无 Flutter 依赖）
│   │   ├── crypto.dart                   # ✅ CLI 复用（Argon2id, AES-GCM）
│   │   └── vault.dart                    # ✅ CLI 复用（vault 解密）
│   ├── domain/                           # 业务逻辑层
│   │   ├── models/
│   │   │   ├── vault_item.dart          # ✅ CLI 复用
│   │   │   ├── vault.dart               # ✅ CLI 复用
│   │   │   └── cli_session.dart         # 会话令牌模型
│   │   └── services/
│   │       ├── ipc_server_service.dart  # Desktop App IPC 服务
│   │       └── cli_session_service.dart # 会话管理服务
│   ├── presentation/                     # Flutter UI（CLI 不使用）
│   └── ...
│
├── cli/                                  # CLI 独立包
│   ├── bin/
│   │   └── hedge.dart                   # CLI 入口
│   ├── lib/
│   │   ├── commands/
│   │   │   ├── get_command.dart
│   │   │   ├── list_command.dart
│   │   │   ├── search_command.dart
│   │   │   ├── lock_command.dart
│   │   │   ├── unlock_command.dart
│   │   │   ├── sync_command.dart         # 新增：WebDAV 同步
│   │   │   └── config_command.dart       # 新增：配置管理
│   │   ├── ipc/
│   │   │   ├── ipc_client.dart          # IPC 客户端
│   │   │   ├── ipc_transport.dart       # 传输层抽象
│   │   │   └── unix_socket_transport.dart
│   │   ├── auth/
│   │   │   ├── auth_manager.dart        # 认证管理器
│   │   │   └── password_auth.dart       # 主密码认证
│   │   ├── services/
│   │   │   ├── keychain_service.dart    # 新增：系统 Keychain 访问
│   │   │   ├── config_service.dart      # 新增：配置管理
│   │   │   └── webdav_sync_service.dart # 新增：WebDAV 同步
│   │   └── session/
│   │       ├── session_manager.dart     # 会话管理
│   │       └── session_storage.dart     # 会话存储（加密文件）
│   └── pubspec.yaml
│       # dependencies:
│       #   args: ^2.4.0                  # 命令行参数解析
│       #   uuid: ^4.5.1                  # UUID 生成
│       #   encrypt: ^5.0.3               # AES-GCM 加密
│       #   cryptography: ^2.7.0         # 密码学算法
│       #   lpinyin: ^2.0.3               # 拼音搜索
│       #   path: ^1.8.3                  # 路径处理
│       #   webdav_client: ^1.2.5        # 新增：WebDAV 客户端
│       # 注：不使用 flutter_secure_storage（Flutter 插件）
└── ...
```

**共享代码**（通过相对导入）：
```dart
// cli/lib/commands/get_command.dart
import '../../lib/src/dart/crypto.dart';  // 相对导入
import '../../lib/src/dart/vault.dart';
import '../../lib/domain/models/vault_item.dart';
```

**CLI 独有代码**：
- IPC 客户端（连接 Desktop App）
- 命令行参数解析
- 会话管理（加密文件存储）
- 错误提示（终端输出）

**编译**：
```bash
# 编译 CLI 为原生可执行文件
cd cli
dart compile exe bin/hedge.dart -o ../build/hedge-cli

# 二进制大小约 8-10MB（包含 Dart VM）
```

### 会话令牌格式

**安全设计**：使用不透明令牌（Opaque Token）而非 JWT，避免 CLI 能够伪造令牌。

```dart
class CliSession {
  final String tokenId;           // 随机 UUID（不透明令牌）
  final DateTime issuedAt;        // 签发时间
  final DateTime expiresAt;       // 过期时间
  final String vaultId;           // Vault UUID
  final AuthMode mode;            // biometric | password
}

// Desktop App 维护会话注册表（内存）
class SessionRegistry {
  final Map<String, CliSession> _sessions = {};

  String createSession(AuthMode mode) {
    final tokenId = Uuid().v4();  // 随机 UUID
    final session = CliSession(
      tokenId: tokenId,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: mode == AuthMode.biometric ? 15 : 5)),
      vaultId: currentVaultId,
      mode: mode,
    );
    _sessions[tokenId] = session;
    return tokenId;
  }

  bool validateSession(String tokenId) {
    final session = _sessions[tokenId];
    if (session == null) return false;
    if (session.expiresAt.isBefore(DateTime.now())) {
      _sessions.remove(tokenId);
      return false;
    }
    return true;
  }

  void revokeSession(String tokenId) {
    _sessions.remove(tokenId);
  }

  void revokeAllSessions() {
    _sessions.clear();
  }
}
```

**CLI 端存储**：令牌存储在加密文件，而非系统 Keychain。

```dart
// CLI 使用 AES-256-GCM 加密存储令牌
class SessionStorage {
  static const _filePath = '~/.hedge/cli-session.enc';

  // 密钥派生：HMAC-SHA256(hostname + username + fixed-salt)
  Uint8List _deriveKey() {
    final hostname = Platform.localHostname;
    final username = Platform.environment['USER'] ?? '';
    final salt = 'hedge-cli-session-v1'; // 固定 salt
    final hmac = Hmac(sha256, utf8.encode(salt));
    return hmac.convert(utf8.encode('$hostname:$username')).bytes;
  }

  Future<void> saveToken(String tokenId) async {
    final key = _deriveKey();
    final encrypted = await encryptAesGcm(tokenId, key);
    await File(_filePath).writeAsBytes(encrypted);
    await File(_filePath).setMode(0x180); // 0600
  }

  Future<String?> loadToken() async {
    if (!await File(_filePath).exists()) return null;
    final encrypted = await File(_filePath).readAsBytes();
    final key = _deriveKey();
    return await decryptAesGcm(encrypted, key);
  }
}
```

**注**：由于 `dart compile exe` 限制，无法使用 `flutter_secure_storage`（Flutter 插件）。加密文件存储对于短期令牌（5-15 分钟）是可接受的安全方案。

### IPC 协议示例

**请求**：
```json
{
  "jsonrpc": "2.0",
  "method": "get_password",
  "params": {
    "session_token": "550e8400-e29b-41d4-a716-446655440000",
    "item_query": "github.com"
  },
  "id": 1
}
```

**响应（成功）**：
```json
{
  "jsonrpc": "2.0",
  "result": {
    "item_id": "uuid",
    "title": "GitHub",
    "username": "user@example.com",
    "password": "secret123",
    "url": "https://github.com"
  },
  "id": 1
}
```

**响应（错误）**：
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": 1002,
    "message": "Session token expired",
    "data": {
      "token_id": "550e8400-e29b-41d4-a716-446655440000",
      "expired_at": "2026-03-11T10:30:00Z"
    }
  },
  "id": 1
}
```

### 错误码分类

| 错误码 | 名称 | 描述 | 用户提示 |
|--------|------|------|----------|
| **1xxx - 认证错误** |
| 1001 | DesktopAppNotFound | Desktop App 未运行 | ⚠️  Desktop App not detected. Falling back to master password mode. |
| 1002 | SessionExpired | 会话令牌过期 | 🔒 Session expired. Please authenticate again. |
| 1003 | SessionInvalid | 会话令牌无效 | ❌ Invalid session token. Please run `hedge unlock`. |
| 1004 | BiometricFailed | 生物识别失败 | ❌ Touch ID authentication failed. |
| 1005 | BiometricCancelled | 用户取消生物识别 | ❌ Touch ID authentication cancelled. |
| 1006 | PasswordIncorrect | 主密码错误 | ❌ Incorrect password. Please try again. (Attempt X/3) |
| 1007 | VaultLocked | Vault 已锁定 | 🔒 Desktop App is locked. Falling back to master password mode. |
| **2xxx - Vault 错误** |
| 2001 | VaultNotFound | Vault 文件未找到 | ❌ Vault file not found. Please specify path with HEDGE_VAULT_PATH. |
| 2002 | VaultCorrupted | Vault 文件损坏 | ❌ Vault file is corrupted. Please restore from backup. |
| 2003 | VaultVersionMismatch | Vault 格式版本不兼容 | ❌ Vault format version X is not supported. Please update Hedge. |
| 2004 | VaultReadTimeout | Vault 文件读取超时 | ❌ Timeout: Vault file took too long to load. Check your network connection. |
| **3xxx - 查询错误** |
| 3001 | ItemNotFound | 密码条目未找到 | ❌ No item found matching "X". |
| 3002 | MultipleItemsFound | 找到多个匹配条目 | ⚠️  Multiple items found. Please be more specific. |
| 3003 | FieldNotFound | 字段不存在 | ❌ Field "X" not found in item "Y". |
| **4xxx - IPC 错误** |
| 4001 | IpcConnectionFailed | IPC 连接失败 | ⚠️  Connection to Desktop App failed. Retrying... |
| 4002 | IpcTimeout | IPC 请求超时 | ❌ Desktop App is not responding. Please restart the app. |
| 4003 | IpcProtocolError | IPC 协议错误 | ❌ Communication error with Desktop App. Please update to the latest version. |
| **5xxx - 系统错误** |
| 5001 | ClipboardFailed | 剪贴板操作失败 | ❌ Failed to copy to clipboard. |
| 5002 | KeychainFailed | Keychain 访问失败 | ❌ Failed to access system keychain. |
| 5003 | PermissionDenied | 权限不足 | ❌ Permission denied. Please check file permissions. |

---

## 🔄 WebDAV 同步支持

### 配置共享架构

**Desktop App 写入 Keychain**（无变化）：
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'webdav_server_url', value: 'https://...');
await storage.write(key: 'webdav_username', value: 'user@example.com');
await storage.write(key: 'webdav_password', value: 'xxx');
await storage.write(key: 'webdav_remote_path', value: 'Hedge/vault.db');
```

**CLI 读取 Keychain**（新增）：
```dart
// cli/lib/services/keychain_service.dart
class KeychainService {
  static Future<String?> read(String key) async {
    if (Platform.isMacOS) {
      return _readFromMacOSKeychain(key);
    } else if (Platform.isLinux) {
      return _readFromLinuxSecretService(key);
    } else if (Platform.isWindows) {
      return _readFromWindowsCredentialManager(key);
    }
    return null;
  }

  static Future<String?> _readFromMacOSKeychain(String key) async {
    // flutter_secure_storage 在 Keychain 中的服务名格式
    final serviceName = 'flutter_secure_storage.$key';

    final result = await Process.run('security', [
      'find-generic-password',
      '-s', serviceName,
      '-w',  // 只输出密码值
    ]);

    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return null;
  }

  static Future<String?> _readFromLinuxSecretService(String key) async {
    final result = await Process.run('secret-tool', [
      'lookup',
      'service', 'flutter_secure_storage',
      'account', key,
    ]);

    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return null;
  }

  static Future<String?> _readFromWindowsCredentialManager(String key) async {
    // Windows 实现（使用 PowerShell 或 FFI）
    // 待实现（v2.0）
    return null;
  }
}
```

### 配置加载优先级

```dart
class CliConfigService {
  static Future<WebDAVConfig?> loadWebDAVConfig() async {
    // 1. 环境变量（最高优先级，适用于 CI/CD）
    if (Platform.environment.containsKey('HEDGE_WEBDAV_URL')) {
      return WebDAVConfig(
        serverUrl: Platform.environment['HEDGE_WEBDAV_URL']!,
        username: Platform.environment['HEDGE_WEBDAV_USERNAME']!,
        password: Platform.environment['HEDGE_WEBDAV_PASSWORD']!,
        remotePath: Platform.environment['HEDGE_WEBDAV_PATH'] ?? 'Hedge/vault.db',
      );
    }

    // 2. 系统 Keychain（与 Desktop App 共享）
    try {
      final serverUrl = await KeychainService.read('webdav_server_url');
      final username = await KeychainService.read('webdav_username');
      final password = await KeychainService.read('webdav_password');
      final remotePath = await KeychainService.read('webdav_remote_path');

      if (serverUrl != null && username != null && password != null) {
        print('✓ Using WebDAV config from system Keychain');
        return WebDAVConfig(
          serverUrl: serverUrl,
          username: username,
          password: password,
          remotePath: remotePath ?? 'Hedge/vault.db',
        );
      }
    } catch (e) {
      print('⚠️  Failed to read from Keychain: $e');
    }

    // 3. CLI 配置文件
    final cliConfig = await _loadFromFile();
    if (cliConfig != null) {
      print('✓ Using WebDAV config from ~/.hedge/cli-config.json');
      return cliConfig;
    }

    // 4. IPC 从 Desktop App 获取
    if (await isDesktopAppRunning()) {
      try {
        final config = await ipcClient.call('get_webdav_config');
        print('✓ Using WebDAV config from Desktop App (IPC)');
        return config;
      } catch (e) {
        // Desktop App 未解锁或拒绝
      }
    }

    // 5. 无配置
    return null;
  }
}
```

### 同步命令实现

**`hedge sync`** - 基本同步：
```bash
$ hedge sync
🔄 Loading WebDAV config from system Keychain...
✓ Config loaded: https://dav.jianguoyun.com/dav/
🔄 Uploading vault.hedge...
✓ Synced successfully
```

**`hedge sync --status`** - 查看状态：
```bash
$ hedge sync --status
✓ Last synced: 2 minutes ago
✓ Remote: https://dav.jianguoyun.com/dav/Hedge/vault.db
✓ No conflicts
```

**冲突处理**：
```bash
$ hedge sync
⚠️  Conflict detected!

Local:  vault.hedge (modified 2 minutes ago)
Remote: vault.hedge (modified 1 minute ago)

Creating backup: vault.hedge.conflict.2026-03-11-10-30-00
✓ Backup created
✓ Using remote version (newer)
```

### 平台兼容性

**macOS**（MVP）：
- ✅ `security` 命令内置
- ✅ 完整支持

**Linux**（v2.0）：
- ⚠️ 需要 `libsecret-tools`
- 检测：`which secret-tool`
- 安装：`sudo apt install libsecret-tools`
- 降级：如果未安装，使用 CLI 配置文件

**Windows**（v2.0）：
- ⚠️ 需要 PowerShell 或 FFI
- 实现复杂度较高
- 降级：使用 CLI 配置文件

---

## 🔗 浏览器插件集成架构

### Native Messaging 协议

浏览器插件通过 Chrome Native Messaging 与 CLI 通信：

```
Browser Extension (JavaScript)
        ↓
Native Messaging Host (JSON over stdin/stdout)
        ↓
hedge CLI (Dart executable)
        ↓
IPC (Unix Socket / Named Pipe)
        ↓
Desktop App (Vault access)
```

### Native Messaging Manifest

**macOS**: `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.hedge.cli.json`

```json
{
  "name": "com.hedge.cli",
  "description": "Hedge Password Manager CLI",
  "path": "/Applications/Hedge.app/Contents/MacOS/hedge-cli",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://abcdefghijklmnopqrstuvwxyz123456/"
  ]
}
```

**注**：Extension ID 在浏览器插件发布时确定，Desktop App 安装时硬编码到 manifest。

### CLI 发现机制

1. **Desktop App 安装时**：自动安装 Native Messaging manifest
2. **浏览器插件安装时**：检查 manifest 是否存在，提示用户安装 Desktop App
3. **CLI 路径**：
   - macOS: 打包在 Desktop App bundle 内（`/Applications/Hedge.app/Contents/MacOS/hedge-cli`）
   - Linux: `/usr/local/bin/hedge`
   - Windows: `C:\Program Files\Hedge\hedge-cli.exe`

### 非交互式认证

浏览器插件调用 CLI 时，CLI 必须非交互式运行：

```bash
# 浏览器插件通过 Native Messaging 调用
echo '{"method":"get_password","params":{"url":"github.com"}}' | hedge --native-messaging
```

CLI 行为：
1. 检测到 `--native-messaging` 标志
2. 尝试连接 Desktop App（IPC）
3. 如果 Desktop App 已解锁，直接返回密码（无需用户交互）
4. 如果 Desktop App 锁定，返回错误（浏览器插件提示用户解锁 Desktop App）
5. 如果 Desktop App 未运行，返回错误（浏览器插件提示用户启动 Desktop App）

**安全模型**：
- 浏览器插件不能触发生物识别提示（避免钓鱼攻击）
- 用户必须先在 Desktop App 解锁 vault
- CLI 仅在 Desktop App 已解锁时返回密码

---

## 📦 CLI 分发与安装

### 分发策略

**方案 A：打包在 Desktop App 内**（推荐）
- CLI 二进制打包在 Desktop App bundle 内
- Desktop App 安装时自动安装 CLI
- 优点：版本同步、安装简单、无需单独分发
- 缺点：CLI 更新需要更新整个 Desktop App

**方案 B：独立分发**
- CLI 作为独立二进制通过 Homebrew / apt / Chocolatey 分发
- 优点：CLI 可独立更新
- 缺点：版本兼容性问题、安装复杂

**MVP 选择**：方案 A（打包在 Desktop App 内）

### 安装流程

**macOS**：
1. 用户安装 Hedge.app
2. Desktop App 首次启动时：
   - 显示一次性设置对话框：
     ```
     To use the CLI, run this command in Terminal:
     sudo ln -s /Applications/Hedge.app/Contents/MacOS/hedge-cli /usr/local/bin/hedge
     ```
   - 用户手动执行命令创建 symlink
3. Desktop App 每次启动时验证 symlink 是否有效，如果失效则再次显示设置对话框
4. 用户在终端运行 `hedge --version` 验证安装

**注**：不自动创建 symlink（避免 sudo 提示），提供清晰的手动安装指引。

**Linux**：
1. 用户通过 .deb / .rpm 安装 Hedge
2. 安装脚本自动：
   - 复制 `hedge-cli` 到 `/usr/local/bin/hedge`
   - 设置可执行权限（`chmod +x`）
   - 安装 Native Messaging manifest

**Windows**：
1. 用户通过 .msi 安装 Hedge
2. 安装程序自动：
   - 复制 `hedge-cli.exe` 到 `C:\Program Files\Hedge\`
   - 添加到 PATH 环境变量
   - 安装 Native Messaging manifest

### 版本兼容性

CLI 和 Desktop App 必须版本兼容：

```dart
// CLI 启动时检查版本
final cliVersion = '1.9.0';
final appVersion = await ipcClient.getAppVersion();

if (!isCompatible(cliVersion, appVersion)) {
  print('❌ CLI version $cliVersion is not compatible with Desktop App version $appVersion');
  print('Please update Hedge Desktop App to the latest version.');
  exit(1);
}
```

兼容性规则：
- 主版本号必须相同（1.x.x）
- 次版本号 CLI <= Desktop App（CLI 1.9.0 可以与 Desktop App 1.9.x 或 1.10.x 兼容）

---

## 🗂️ Vault 文件发现机制

### 独立模式下的 Vault 路径

CLI 在独立模式下需要直接访问 vault 文件（**只读访问**，MVP 不支持写操作）。发现顺序：

1. **环境变量**：`HEDGE_VAULT_PATH`
   ```bash
   export HEDGE_VAULT_PATH="/path/to/vault.hedge"
   hedge get github --no-app
   ```

2. **配置文件**：`~/.hedge/config.yaml`
   ```yaml
   vault_path: /Users/username/Library/Mobile Documents/com~apple~CloudDocs/Hedge/vault.hedge
   ```

3. **默认路径**（按顺序尝试）：
   - macOS: `~/Library/Mobile Documents/com~apple~CloudDocs/Hedge/vault.hedge`（iCloud Drive）
   - Linux: `~/.local/share/hedge/vault.hedge`
   - Windows: `%APPDATA%\Hedge\vault.hedge`

4. **询问 Desktop App**（如果 IPC 可用但 vault 锁定）：
   ```dart
   final vaultPath = await ipcClient.getVaultPath();
   ```

5. **交互式提示**（最后手段）：
   ```
   ⚠️  Vault file not found. Please specify the path:
   Vault path: _
   ```

### Vault 格式版本兼容性

CLI 检查 vault 文件格式版本：

```dart
final vaultFormatVersion = vault.metadata['format_version'];
final supportedVersions = ['1.0', '1.1'];

if (!supportedVersions.contains(vaultFormatVersion)) {
  print('❌ Vault format version $vaultFormatVersion is not supported by this CLI version');
  print('Please update Hedge Desktop App to migrate the vault.');
  exit(1);
}
```

---

## 📋 开发计划

### 阶段一：核心基础设施（1周）

1. 创建 CLI 项目结构（`cli/` 目录）
2. 配置 `cli/pubspec.yaml`（依赖主应用）
3. 实现 `CliSession` 模型（不透明令牌）
4. 实现 `SessionRegistry`（Desktop App 端）
5. 实现会话令牌存储（`SessionStorage` 使用 `flutter_secure_storage`）
6. 实现 IPC 传输层抽象（`IpcTransport`）
7. 实现 Unix Socket 传输（macOS/Linux）
8. 编写单元测试

---

### 阶段二：Desktop App IPC Server（1周）

9. 创建 `IpcServerService`
10. 实现 JSON-RPC 2.0 协议处理
11. 实现后台 isolate 运行
12. 实现 UID 验证
13. 实现会话令牌验证（查询 `SessionRegistry`）
14. 实现 "vault locked" 事件推送（`revokeAllSessions()`）
15. 添加 "Enable CLI Access" 设置
16. 实现版本兼容性检查（`getAppVersion` 方法）
17. 编写集成测试

---

### 阶段三：CLI 命令实现（1周）

18. 实现 `AuthManager`（混合认证逻辑）
19. 实现 `IpcClient`（连接 Desktop App）
20. 实现 Vault 文件发现机制（环境变量、配置文件、默认路径）
21. 实现 `GetCommand`
22. 实现 `ListCommand`
23. 实现 `SearchCommand`
24. 实现 `LockCommand`
25. 实现 `UnlockCommand`
26. 实现命令行参数解析（使用 `args` 包）
27. 实现错误处理和用户提示（使用错误码分类）
28. 编写端到端测试

---

### 阶段四：独立模式（主密码认证）（3天）

29. 实现直接 vault 文件访问
30. 复用 `CryptoService` 的 Argon2id 密钥派生
31. 复用 `VaultService` 的 vault 解密
32. 实现主密码输入提示（隐藏输入，使用 `dart:io` stdin）
33. 实现失败重试和指数退避
34. 实现 vault 格式版本兼容性检查
35. 编写安全测试

---

### 阶段五：浏览器插件集成（3天）

36. 实现 `--native-messaging` 标志
37. 实现 stdin/stdout JSON 通信（Native Messaging 协议）
38. 实现非交互式认证（仅在 Desktop App 已解锁时返回密码）
39. 创建 Native Messaging manifest 模板
40. 实现 Desktop App 安装时自动安装 manifest
41. 编写浏览器插件集成测试

---

### 阶段六：CLI 分发与安装（2天）

42. 实现 CLI 编译脚本（`dart compile exe`）
43. 实现 Desktop App 打包时包含 CLI 二进制
44. 实现 Desktop App 首次启动时创建 symlink（macOS/Linux）
45. 实现 Windows 安装程序添加 PATH
46. 实现版本兼容性检查（CLI 启动时）
47. 编写安装测试脚本

---

### 阶段七：打磨与优化（3天）

48. 实现超时处理（IPC 连接 5 秒、vault 文件读取 30 秒）
49. 优化错误提示文案（中英文）
50. 添加 `--help` 和 `--version`
51. 实现剪贴板操作（`hedge get` 默认复制）
52. 添加 `--verbose` 标志（调试输出）
53. 性能测试（命令响应时间 < 1 秒）
54. 内存泄漏检查

---

### 阶段八：国际化（1天）

55. CLI 错误提示国际化（使用独立 JSON 文件，不依赖 Flutter `.arb`）
56. 创建 `cli/lib/l10n/en.json` 和 `cli/lib/l10n/zh.json`
57. 实现语言检测（`Platform.localeName`）

---

### 阶段九：文档与测试（2天）

58. 编写 README（安装、使用、故障排除）
59. 编写架构文档（IPC 协议、认证流程）
60. 编写安全文档（威胁模型、错误码）
61. 手动测试（真实 macOS 环境）
62. 修复发现的 bug
63. 代码审查

---

## 📊 验收标准

### 功能完整性
- ✅ 支持 5 个核心命令（get, list, search, lock, unlock）
- ✅ 支持混合认证模式（自动检测）
- ✅ 支持生物识别认证（Touch ID/Face ID）
- ✅ 支持主密码认证（降级模式）
- ✅ 会话令牌加密存储
- ✅ IPC 协议完整实现
- ✅ Desktop App IPC Server 运行稳定

### 性能指标
- ✅ CLI 命令响应时间 < 1 秒（生物识别模式）
- ✅ CLI 命令响应时间 < 3 秒（主密码模式，含 Argon2id）
- ✅ IPC 连接超时：5 秒
- ✅ Vault 文件读取超时：30 秒
- ✅ 会话令牌过期：15 分钟（生物识别）/ 5 分钟（主密码）

### 安全性
- ✅ 会话令牌使用不透明 UUID（无法伪造）
- ✅ 会话令牌存储在加密文件（AES-256-GCM + 设备特征派生密钥）
- ✅ 文件权限 0600（仅所有者可读写）
- ✅ Desktop App 维护会话注册表（内存，不持久化）
- ✅ IPC socket 权限限制（0600）
- ✅ UID 验证（防止跨用户攻击）
- ✅ 主密码输入隐藏
- ✅ 失败重试指数退避
- ✅ 无敏感信息日志
- ✅ 浏览器插件无法触发生物识别（防钓鱼）
- ✅ IPC 超时 5 秒（防止 Desktop App 挂起）

### 用户体验
- ✅ 自动检测认证模式（零配置）
- ✅ 清晰的错误提示
- ✅ 优雅降级（Desktop App 崩溃/未运行）
- ✅ 支持管道操作（`hedge get | pbcopy`）
- ✅ 详细的 `--help` 文档

### 代码质量
- ✅ 单元测试覆盖率 > 80%
- ✅ 集成测试覆盖核心流程
- ✅ 端到端测试覆盖用户故事
- ✅ 通过 `flutter analyze`
- ✅ 符合项目架构规范

---

## 🚀 平台支持

### MVP (v1.9.0)
- ✅ macOS（优先）

### 未来 (v2.0.0)
- ⏳ Linux
- ⏳ Windows

---

## 📝 后续优化方向

### v2.0.0 可能的增强
- Daemon 模式（持久后台进程，避免每次重新认证）
- 写操作命令（`add`, `edit`, `delete`）
- Shell 补全（bash, zsh, fish）
- 配置文件支持（`~/.hedge/config.yaml`）
- Linux 和 Windows 平台支持
- 更多字段支持（TOTP, 附件）

---

## ❓ 常见问题

**Q1: 为什么 CLI 需要 Desktop App？**
A: 生物识别认证需要 Desktop App 提供。但 CLI 也支持独立模式（主密码），不依赖 Desktop App。

**Q2: 会话令牌安全吗？**
A: 会话令牌加密存储，文件权限 0600，短期过期（5-15 分钟），Desktop App 锁定时立即失效。

**Q3: 能否在 CI/CD 环境使用？**
A: 可以。使用 `--no-app` 标志强制独立模式，通过环境变量 `HEDGE_MASTER_PASSWORD` 提供主密码。

**Q4: 支持多个并发 CLI 进程吗？**
A: 支持。每个 CLI 进程可以有独立的会话令牌（Desktop App 的 `SessionRegistry` 支持多个并发会话）。系统 Keychain API 本身是线程安全的，无需额外的文件锁。

**Q5: 浏览器插件如何使用 CLI？**
A: 浏览器插件通过 Native Messaging 调用 CLI，CLI 通过 IPC 访问 Desktop App 的 vault。

---

## ⚠️ 技术风险与缓解措施

### 高风险

**1. IPC 连接可靠性**
- **风险**：Desktop App 崩溃或挂起导致 CLI 无法响应
- **缓解**：5 秒超时 + 自动降级到独立模式
- **状态**：已设计

**2. 会话令牌安全性**
- **风险**：加密文件存储不如系统 Keychain 安全
- **缓解**：AES-256-GCM + 设备特征派生密钥 + 短期过期（5-15 分钟）
- **状态**：已设计，文档化为已知限制

### 中风险

**3. Dart SDK 版本不匹配**
- **风险**：CLI 和 Desktop App 使用不同 Dart SDK 导致加密行为不一致
- **缓解**：CI 强制检查 SDK 版本一致性 + 文档说明
- **状态**：需要在 CI 中实现

**4. Vault 格式版本兼容性**
- **风险**：Desktop App 更新 vault 格式后 CLI 无法读取
- **缓解**：CLI 启动时检查 vault 格式版本，拒绝不支持的版本
- **状态**：已设计

**5. IPC Server 阻塞 UI**
- **风险**：IPC Server 在主 isolate 运行可能阻塞 UI
- **缓解**：监控测试，如有问题则移到后台 isolate（v2.0）
- **状态**：MVP 接受此风险

### 低风险

**6. 搜索性能（大型 vault）**
- **风险**：10,000+ 条目时搜索可能慢
- **缓解**：线性搜索约 10ms，可接受；v2.0 优化
- **状态**：MVP 接受此风险

**7. Symlink 创建失败**
- **风险**：用户权限不足或路径不存在
- **缓解**：提供清晰的手动安装指引 + 验证机制
- **状态**：已设计

**8. Native Messaging 设置复杂性**
- **风险**：多浏览器、多配置文件场景复杂
- **缓解**：MVP 提供手动指引，v1.9.1 自动化
- **状态**：延后到 v1.9.1

---

## 🔗 依赖关系

### 前置依赖
- ✅ v1.8.0 密码生成器（已完成）
- ✅ Desktop App 生物识别解锁（已完成）
- ✅ Vault 加密/解密逻辑（已完成）

### 后续依赖
- 🎯 v1.9.0 浏览器插件（依赖 CLI Foundation）
- 🎯 v2.0.0 HTTP API Server（依赖 CLI Foundation）

---

**文档状态**: 评审通过
**责任人**: Flutter 开发团队
**最后更新**: 2026-03-11
