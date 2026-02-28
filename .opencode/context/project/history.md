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
