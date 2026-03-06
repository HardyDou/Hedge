# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.1] - 2026-03-06

### Changed
- **Docs**: 重新整理文档结构，精简为 6 个核心文档
  - 删除 7 个重复/过时文档
  - 保留核心文档：README, AGENTS, CHANGELOG, 产品规划, PRD, 技术架构
  - AGENTS.md 全面中文化，新增 TOTP/2FA 技术约定
  - README.md 更新功能列表和路线图
  - 统一中文命名，职责清晰

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
