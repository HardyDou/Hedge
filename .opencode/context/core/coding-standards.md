# Coding Standards & Guidelines

## 1. Internationalization (i18n) - **P0 Requirement**
*   **NO Hardcoded Strings**. All UI text MUST be extracted to ARB files (`lib/l10n/`).
*   When adding new features, **MUST synchronize** updates to `app_en.arb` and `app_zh.arb`.
*   Access using `AppLocalizations.of(context)!`.

## 2. UI/UX Specifications
*   **Platform Adaptation:** Use `PlatformUtils` to detect platform.
    *   **Mobile:** Stack navigation (Push/Pop).
    *   **Desktop:** Two-column layout (List + Detail) + Dialogs.
*   **Components:** Prioritize `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoButton`, etc.
*   **Dark Mode:** MUST test performance in Dark Mode.

## 3. Platform Specifics
*   **macOS:**
    *   Network requests require `com.apple.security.network.client` entitlement.
    *   System Menu (Menu Bar) modification requires `DispatchQueue.main.async` delayed patch.
*   **iOS:**
    *   Simulator does not enable FaceID by default; manually enable via `Features -> Face ID -> Enrolled`.
*   **Android:**
    *   Be aware of Kotlin `Result` type inference issues during build.

## 4. Common Pitfalls
*   **Do NOT use Material components:** Unless for specific effects, fully embrace Cupertino.
*   **Do NOT assume Rust is available:** Crypto layer is now Dart.
*   **Do NOT ignore Desktop:** When making UI changes, always consider "How does this look on a wide macOS screen?".
*   **Do NOT overwrite user data:** In sync conflicts, ALWAYS choose **"Keep Both"** and append a suffix to the filename.

## 5. UI/UX Design Guideline

*   **原则:** 无需详细描述交互方式。**请遵循 Apple Human Interface Guidelines (HIG)**。
*   **iOS/macOS:** 使用 Cupertino Widgets，遵循 iOS/macOS 原生交互习惯。
*   **移动端:** 遵循 iOS 交互规范 (如: 底部弹出菜单、滑动删除)
*   **桌面端:** 遵循 macOS 交互规范 (如: 菜单栏、快捷键)
*   **如果不确定怎么做:** 直接参考 1Password 或 Apple 自带 App 的交互方式。
