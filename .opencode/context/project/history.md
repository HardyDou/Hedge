# Lessons Learned & Historical Context

## 1. Why were PRD features missed?
*   **Sprint Goal too narrow**: Focused on MVP, missed Import/Search.
*   **Lack of Checklist**: Did not check against PRD item by item.
*   **State Management inertia**: Focused on UI, missed complex logic (i18n).

## 2. Countermeasures
*   **Align with PRD before starting**: Must scan `Functional Requirements` in PRD.
*   **Modular Verification**: Cross-check Crypto, UI, Sync.
*   **i18n First**: Create ARB keys immediately when adding features.

## 3. Technical Reflections

### 3.1 Simulator Biometrics
*   **Issue**: iOS Simulator FaceID off by default.
*   **Fix**: Manually enable via `Features -> Face ID -> Enrolled`.

### 3.2 Internationalization (i18n)
*   **Lesson**: Introduce `flutter_localizations` early. Refactoring hardcoded strings is painful.

### 3.3 Import Complexity
*   **Analysis**: 1Password `.1pux` is a zip with encrypted JSON. Parsing logic is heavy.

### 3.4 UnlockPage Context Bug (2026-02-28)
*   **Issue**: Clicking "Reset Vault" button had no response.
*   **Root Cause**: In ActionSheet, `Navigator.pop(context)` invalidated the context before calling `_showResetConfirmDialog(context)`.
*   **Fix**: Rename builder context to `sheetContext` to preserve parent context for dialogs.

### 3.5 Biometric Type Detection
*   **Issue**: "Use Biometrics" text shown instead of specific Face ID/Touch ID.
*   **Fix**: Added `_detectBiometricType()` in `VaultProvider` using `local_auth.getAvailableBiometrics()`.
*   **Fallback**: If specific type not detected but biometrics available, default to generic text.

### 3.6 Stack Layout for UnlockPage
*   **Goal**: Position "Forgot Password" at bottom, Bio button prominent.
*   **Solution**: Use `Stack` with `Positioned` for bottom elements, `Center` for main content.
*   **Benefit**: Better control over element placement independent of scroll.

## 4. macOS Desktop Experience (2026-02-27)

### 4.1 System Menu "Settings" Greyed Out
*   **Root Cause**: `MainMenu.xib` items had no Target/Action.
*   **Fix**: `DispatchQueue.main.async` patch in `AppDelegate` to find and modify the menu item.
*   **Key**: Do NOT rebuild the whole menu. Patch it.

### 4.2 Desktop Icon (favicon) Missing
*   **Root Cause**: App Sandbox missing network permission.
*   **Fix**: Add `com.apple.security.network.client` to Entitlements.

### 4.3 Android Build Failure (Kotlin Result)
*   **Root Cause**: `Result(null)` type inference ambiguity.
*   **Fix**: Explicit type in function signature.

## 5. Migration History
*   **Rust to Dart**: Migrated crypto layer to pure Dart to simplify iOS build.
*   **Material to Cupertino**: Full UI migration to iOS style.
