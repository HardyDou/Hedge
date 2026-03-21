# Hedge（密码本）

[English](#english) | [中文](#中文)

---

## English

# Hedge

**Local-First** cross-platform password manager with native experience.

Your passwords, your cloud, your control.

---

## ✨ Core Features

- **Zero-Knowledge Architecture** - Local encryption (AES-256-GCM), never touches third-party servers
- **Your Cloud, Your Control** - Supports iCloud Drive / WebDAV sync, no vendor lock-in
- **Native Experience** - 100% Cupertino design, pixel-perfect on iOS/macOS/Android
- **Biometric Unlock** - Face ID / Touch ID / Fingerprint support
- **Cross-Platform** - iOS, Android, macOS, Linux, Windows
- **TOTP/2FA** - Built-in authenticator, no extra app needed
- **Password Generator** - Configurable strength, history tracking
- **CLI** - Terminal access with Touch ID support
- **Desktop Quick Panel** - System tray resident, hover to show details

---

## 🆚 Why Choose Hedge?

| Aspect | Hedge | 1Password | Bitwarden | KeePass |
|---|:---:|:---:|:---:|:---:|
| **Data Storage** | Your Cloud | Vendor Server | Vendor/Self-hosted | Local |
| **Price** | Free | $2.99+/mo | Free/$10/yr | Free |
| **UI Experience** | Native | Native | Web-style | Outdated |
| **Cross-Platform** | ✅ All | ✅ | ✅ | ⚠️ Limited |
| **TOTP** | ✅ | ✅ | ✅ | ⚠️ Plugin |
| **Desktop Quick Access** | ✅ Tray Panel | ✅ | ⚠️ Basic | ❌ |

---

## 🚀 Quick Start

### Requirements

- Flutter 3.x
- Xcode 15+ (iOS/macOS)
- Android Studio (Android)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Generate code (JSON serialization, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Run on macOS
flutter run -d macos

# Run on iOS Simulator
flutter run -d iphonesimulator

# Run on Android
flutter run -d android
```

---

## 📱 Features

### Core
- ✅ Password management (CRUD)
- ✅ AES-256-GCM encryption + Argon2id key derivation
- ✅ Biometric unlock
- ✅ Auto-lock
- ✅ Attachment support
- ✅ Markdown notes editor

### TOTP/2FA
- ✅ Scan QR code to add
- ✅ Manual secret key input
- ✅ 6-digit code + 30s countdown
- ✅ One-tap copy

### Password Generator (v1.8.0)
- ✅ Configurable length (8-64 characters)
- ✅ Toggle character types (uppercase, lowercase, digits, symbols)
- ✅ Exclude ambiguous characters option
- ✅ Real-time password strength indicator
- ✅ One-tap generate and fill
- ✅ Remember user preferences
- ✅ Password history (keep last 10 versions)

### Sync
- ✅ Local storage
- ✅ iCloud Drive (iOS/macOS)
- ✅ WebDAV (all platforms)
  - Supports Nutstore, Nextcloud, Synology NAS
- ✅ Conflict detection & backup

### CLI (v1.9.0)
- ✅ `hedge get <item>` - Get password
- ✅ `hedge list` - List all items
- ✅ `hedge search <query>` - Search
- ✅ `hedge lock` - Lock session
- ✅ Biometric authentication (Touch ID/Face ID)
- ✅ Master password fallback (--no-app mode)
- ✅ Encrypted token storage
- ✅ macOS/Linux/Windows support

### 🤖 Claude Code Skill (Fully Automated)

Hedge includes a Claude Code skill. **Agent handles everything automatically** - no user action needed.

**What Agent does automatically:**
1. Install this skill (symlink or npx skills add)
2. Build Hedge CLI (`dart compile exe`)
3. Execute commands and handle authentication

**User just says:**
- "Get my GitHub password" → Done!
- "List all passwords" → Done!
- "Search for AWS" → Done!
- "Sync my vault" → Done!

**Publish to skills.sh:**
Push to GitHub → `npx skills add <org>/hedge-cli-skill`

### User Experience
- ✅ 100% Cupertino design
- ✅ Dark mode (follows system)
- ✅ Pinyin sorting (numbers → letters → pinyin)
- ✅ Mobile alphabet index bar
- ✅ Desktop dual-pane layout
- ✅ Real-time search (pinyin support)
- ✅ i18n (Chinese/English)

### Desktop Features
- ✅ System tray resident
- ✅ Quick panel (hover to show details)
- ✅ Background running
- ✅ Draggable split view

### Data Import
- ✅ Chrome CSV
- ✅ 1Password CSV
- ✅ Bitwarden CSV

---

## 🏗️ Architecture

```
lib/
├── src/dart/           # Core business logic (Vault, Crypto)
├── domain/             # Domain layer (Services, Use Cases)
├── presentation/       # UI layer (Cupertino widgets, Riverpod)
│   ├── mobile/         # iOS/Android screens
│   ├── desktop/        # macOS/Linux/Windows screens
│   └── shared/         # Shared screens (unlock, onboarding)
├── features/           # Feature modules (tray panel)
├── platform/           # Platform adapters (sync services)
└── l10n/               # Internationalization (Chinese/English)
```

**Architecture Pattern**: MVVM + Clean Architecture
**State Management**: Riverpod
**Detailed Design**: See `docs/技术架构.md`

---

## 🔒 Security

- **Encryption**: AES-256-GCM
- **Key Derivation**: Argon2id
- **Zero Plaintext Logs**: All sensitive logs disabled in production
- **Biometric Auth**: Local verification, keys never leave device
- **Zero-Knowledge**: Data encrypted locally before storage, cloud only has ciphertext

---

## 📅 Roadmap

- ✅ **v1.7.0** - TOTP/2FA support + Windows
- ✅ **v1.8.0** - Password generator + strength checker + history
- 🎯 **v1.9.0** (Current) - CLI + Browser extension
- 🎯 **v2.0.0** (2026-09) - Folder system + batch operations

Detailed plan: See `docs/产品规划.md`

---

## 📚 Documentation

- **`AGENTS.md`** - AI development assistant manual
- **`docs/产品规划.md`** - Product roadmap
- **`docs/PRD.md`** - Complete product requirements
- **`docs/技术架构.md`** - System architecture design

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Development Workflow
1. Fork this repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Create Pull Request

### Code Standards
- 100% Cupertino components (Material disabled)
- Follow technical conventions in `AGENTS.md`
- Run `flutter analyze` and `flutter test` before committing

---

## 📄 License

MIT License

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - Cross-platform UI framework
- [Riverpod](https://riverpod.dev/) - State management
- [otp](https://pub.dev/packages/otp) - TOTP generation
- [lpinyin](https://pub.dev/packages/lpinyin) - Chinese pinyin conversion

---

**Made with ❤️ by Hedge Team**

---
---

## 中文

# Hedge（密码本）

**Local-First** 跨平台密码管理器，原生体验。

你的密码，你的云盘，你的掌控。

---

## ✨ 核心特性

- **零知识架构** - 数据本地加密（AES-256-GCM），永不触碰第三方服务器
- **你的云盘，你做主** - 支持 iCloud Drive / WebDAV 同步，无厂商锁定
- **原生体验** - 100% Cupertino 设计，iOS/macOS/Android 像素级完美
- **生物识别解锁** - Face ID / Touch ID / 指纹支持
- **全平台支持** - iOS、Android、macOS、Linux、Windows
- **TOTP/2FA** - 内置动态验证码，无需额外 App
- **桌面快捷面板** - 系统托盘常驻，悬停显示详情

---

## 🆚 为什么选择 Hedge？

| 维度 | Hedge | 1Password | Bitwarden | KeePass |
|---|:---:|:---:|:---:|:---:|
| **数据存储** | 你的云盘 | 厂商服务器 | 厂商/自托管 | 本地 |
| **价格** | 免费 | $2.99+/月 | 免费/$10/年 | 免费 |
| **UI 体验** | 原生 | 原生 | Web 风格 | 老旧 |
| **跨平台** | ✅ 全平台 | ✅ | ✅ | ⚠️ 有限 |
| **TOTP** | ✅ | ✅ | ✅ | ⚠️ 插件 |
| **桌面快捷访问** | ✅ 托盘面板 | ✅ | ⚠️ 基础 | ❌ |

---

## 🚀 快速开始

### 环境要求

- Flutter 3.x
- Xcode 15+ (iOS/macOS)
- Android Studio (Android)

### 构建运行

```bash
# 安装依赖
flutter pub get

# 生成代码（JSON 序列化等）
flutter pub run build_runner build --delete-conflicting-outputs

# 生成国际化文件
flutter gen-l10n

# 运行 macOS
flutter run -d macos

# 运行 iOS 模拟器
flutter run -d iphonesimulator

# 运行 Android
flutter run -d android
```

---

## 📱 功能列表

### 核心功能
- ✅ 密码管理（增删改查）
- ✅ AES-256-GCM 加密 + Argon2id 密钥派生
- ✅ 生物识别解锁
- ✅ 自动锁定
- ✅ 附件支持
- ✅ Markdown 备注编辑器

### TOTP/2FA
- ✅ 扫描 QR 码添加
- ✅ 手动输入 Secret Key
- ✅ 6 位验证码 + 30 秒倒计时
- ✅ 一键复制验证码

### 同步功能
- ✅ 本地存储
- ✅ iCloud Drive（iOS/macOS）
- ✅ WebDAV（所有平台）
  - 支持坚果云、Nextcloud、Synology NAS
- ✅ 冲突检测与备份

### 🤖 Claude Code Skill

Hedge 内置 Claude Code skill，支持 AI 代理集成。

**先构建 CLI:**
```bash
cd cli && dart pub get && dart compile exe bin/hedge.dart -o ../build/hedge
```

**通过 skills.sh 安装（推荐）：**
```bash
# 发布到 GitHub 后
npx skills add <owner>/hedge-cli-skill
```

**或手动链接：**
```bash
ln -s /path/to/hedge/skills/hedge-cli ~/.claude/skills/hedge-cli
```

**AI Agent 使用方式：**
- "获取我的 GitHub 密码" → `hedge get github`
- "列出所有密码" → `hedge list`
- "搜索 AWS" → `hedge search aws`
- "同步我的密码库" → `hedge sync`

**发布到 skills.sh：**
推送后，任何人可安装：
`npx skills add <你的组织>/hedge-cli-skill`

### 用户体验
- ✅ 100% Cupertino 设计
- ✅ 深色模式（跟随系统）
- ✅ 拼音排序（数字 → 字母 → 拼音）
- ✅ 移动端字母索引栏
- ✅ 桌面端双栏布局
- ✅ 实时搜索（支持拼音）
- ✅ 国际化（中文/英文）

### 桌面端特色
- ✅ 系统托盘常驻
- ✅ 快捷面板（悬停显示详情）
- ✅ 后台运行
- ✅ 可拖拽分割线

### 数据导入
- ✅ Chrome CSV
- ✅ 1Password CSV
- ✅ Bitwarden CSV

---

## 🏗️ 架构

```
lib/
├── src/dart/           # 核心业务逻辑（Vault, Crypto）
├── domain/             # 领域层（Services, Use Cases）
├── presentation/       # UI 层（Cupertino widgets, Riverpod）
│   ├── mobile/         # iOS/Android 页面
│   ├── desktop/        # macOS/Linux/Windows 页面
│   └── shared/         # 共享页面（解锁、引导）
├── features/           # 功能模块（托盘面板）
├── platform/           # 平台适配（同步服务）
└── l10n/               # 国际化（中文/英文）
```

**架构模式**: MVVM + Clean Architecture
**状态管理**: Riverpod
**详细设计**: 查看 `docs/技术架构.md`

---

## 🔒 安全性

- **加密算法**: AES-256-GCM
- **密钥派生**: Argon2id
- **零明文日志**: 生产环境禁用所有敏感日志
- **生物识别**: 本地验证，密钥不离开设备
- **零知识架构**: 数据在本地加密后存储，云端只有密文

---

## 📅 路线图

- ✅ **v1.7.0** (当前) - TOTP/2FA 支持
- 🎯 **v1.8.0** (2026-04) - 密码生成器 + 强度检测 + 历史记录
- 🎯 **v1.9.0** (2026-06) - 浏览器插件 + 安全审计
- 🎯 **v2.0.0** (2026-09) - 文件夹系统 + 批量操作

详细规划：查看 `docs/产品规划.md`

---

## 📚 文档

- **`AGENTS.md`** - AI 开发助手操作手册
- **`docs/产品规划.md`** - 产品路线图
- **`docs/PRD.md`** - 完整产品需求文档
- **`docs/技术架构.md`** - 系统架构设计

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发流程
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- 100% Cupertino 组件（禁用 Material）
- 遵循 `AGENTS.md` 中的技术约定
- 提交前运行 `flutter analyze` 和 `flutter test`

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Riverpod](https://riverpod.dev/) - 状态管理
- [otp](https://pub.dev/packages/otp) - TOTP 生成
- [lpinyin](https://pub.dev/packages/lpinyin) - 中文拼音转换

---

**Made with ❤️ by Hedge Team**
