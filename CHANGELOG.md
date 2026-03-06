# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-01-09

### Added
- **Markdown Editor**: 备注区域支持 Markdown 格式编辑和预览
- **Markdown Toolbar**: 添加格式化工具栏（加粗、斜体、标题、列表、分隔线、代码块）
- **Mobile**: 全屏 Markdown 编辑器，支持实时预览切换
- **Desktop**: 编辑面板集成 Markdown 编辑器和工具栏
- **UI**: 字母索引栏（桌面端侧边栏）
- **UI**: 分组密码列表（按首字母分组）
- **UI**: 详情页面自动隐藏空字段

### Changed
- **UI**: 预览/编辑切换按钮移至导航栏/标题行，语义更明确
- **UI**: 工具栏固定显示，预览模式按钮变灰禁用，避免内容跳动
- **UI**: 优化背景色层次（外层 #000000/#F2F2F7，内容区 #1C1C1E/white）

### Fixed
- **Desktop**: 新增页面备注区域始终显示预览/编辑按钮

## [1.1.0] - 2026-02-28

### Added
- **Architecture**: Created `shared/` directory for cross-platform pages.
- **Security**: Background isolates for crypto operations to improve performance.
- **UI**: Automatic Face ID / Touch ID detection and display.
- **UI**: UnlockPage redesign with Stack layout (bio button above input, forgot password at bottom).

### Changed
- **UI**: Complete removal of Material dependencies (100% Cupertino).
- **Theme**: Replaced Material `ThemeMode` with custom `AppThemeMode`.
- **L10n**: Added specific biometric strings (Face ID / Touch ID).

### Fixed
- **UnlockPage**: Fixed ActionSheet context issue in reset flow.
- **UI**: Replaced Material `SelectableText` and `Divider` with Cupertino equivalents.

## [1.7.0] - 2026-03-06

### Added
- **TOTP**: 完整实现 TOTP 动态验证码功能
  - 支持手动输入密钥添加 TOTP
  - 支持扫描二维码添加 TOTP（移动端）
  - 支持从图片识别二维码添加 TOTP（桌面端）
  - 实时显示验证码和倒计时
  - 一键复制验证码
  - 支持自定义 TOTP 参数（算法、位数、时间步长）
- **Platform**: Windows 平台支持

### Changed
- **Build**: 优化构建配置，移除 macOS 自动发布（需要代码签名）

### Fixed
- **macOS**: 修复快捷面板生物解锁后消失和自动锁屏的问题
- **macOS**: 修复构建路径和部署目标问题

## [1.6.1] - 2026-03-05

### Fixed
- **macOS**: 修复快捷面板生物解锁后消失和自动锁屏的问题
- **macOS**: 修复构建路径和部署目标问题

## [Unreleased]

### Added
- **Desktop**: Two-column layout (List + Detail) for macOS/Linux/Windows.
- **Desktop**: Real-time search in sidebar.
- **Desktop**: Settings dialog with Cupertino styling.
- **Desktop**: Drag-and-drop support for list/detail divider.
- **Desktop**: Dark mode support (follows system).
- **Core**: `AppLock` integration for automatic timeout locking.
- **UI**: Full migration from Material to Cupertino widgets.
- **UI**: Large Password display (using system rotation).
- **Security**: Zero-knowledge encryption architecture.

### Changed
- **Architecture**: Migrated core crypto logic from Rust FFI to pure Dart (`cryptography` + `encrypt`) for better iOS compatibility.
- **Storage**: Optimized `VaultStorage` to use encrypted JSON.

### Fixed
- **macOS**: System menu "Settings" item was disabled; patched via `AppDelegate`.
- **macOS**: App sandbox network permission missing; added entitlement.
- **Android**: Build error due to Kotlin `Result` type ambiguity.
