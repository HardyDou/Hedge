# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
