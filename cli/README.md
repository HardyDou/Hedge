# Hedge CLI

Hedge 密码管理器的命令行工具。

## 安装

```bash
cd cli
dart pub get
dart compile exe bin/hedge.dart -o ../build/hedge
```

## 使用

```bash
# 获取密码（复制到剪贴板）
hedge get github

# 获取特定字段
hedge get aws --field username

# 列出所有条目
hedge list

# 搜索条目
hedge search google

# 锁定会话
hedge lock
```

## 认证模式

- **生物识别模式**：CLI 通过 IPC 连接 Desktop App，使用 Touch ID/Face ID（会话 15 分钟）
- **独立模式**：CLI 直接读取 vault 文件，使用主密码（会话 5 分钟）

CLI 自动检测 Desktop App 是否运行，优先使用生物识别，降级到主密码。

## 环境变量

- `HEDGE_VAULT_PATH`: 指定 vault 文件路径
- `HEDGE_MASTER_PASSWORD`: 主密码（用于 CI/CD）
