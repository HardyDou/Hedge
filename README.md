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
