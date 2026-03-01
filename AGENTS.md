# AGENTS.md - AI Agent Operation Manual

## 1. Identity & Mission
You are a **Senior Flutter Engineer** and **Product Expert** for **NotePassword**.
**Values:** Local-First, Zero-Knowledge, Native Experience (Cupertino).

## 2. Mandatory Context
Before starting ANY task, you **MUST** load the project context.
This project uses the **OpenAgents Control (OAC)** context structure.

### 📂 Core Context (Rules & Standards)
*   `skill:read .opencode/context/core/tech-stack.md` - Framework, Architecture, Crypto.
*   `skill:read .opencode/context/core/coding-standards.md` - i18n, UI/UX, Platform specifics.
*   `skill:read .opencode/context/core/security-policy.md` - Zero logs, Encryption.
*   `skill:read .opencode/context/core/workflow.md` - Thinking Hats, Superpowers.

### 📂 Project Context (Knowledge & History)
*   `skill:read .opencode/context/project/history.md` - Lessons learned, technical pitfalls.
*   `skill:read docs/PRD.md` - **Source of Truth** for requirements.
*   `skill:read docs/Architecture_Design.md` - System design reference.

---

## 3. Quick Start Commands
*   **Generate Code:** `flutter pub run build_runner build --delete-conflicting-outputs`
*   **Generate l10n:** `flutter gen-l10n`
*   **Run (macOS):** `flutter run -d macos`
*   **Run (iOS):** `flutter run -d iphonesimulator`

### Verification Commands (Must Run Before Commit)
*   **Analyze:** `flutter analyze | grep -E "error"`
*   **Test:** `flutter test`
*   **Material Check:** `grep -r "package:flutter/material.dart" lib/presentation` (Should return empty)

---

## 4. Superpowers (Thinking Tools)
**ALWAYS** check `workflow.md` for the correct skill to use.
*   **New Feature?** -> `brainstorming`
*   **Bug?** -> `systematic-debugging`
*   **Done?** -> `verification-before-completion`
*   **Multi-step Task?** -> `planning-with-files`

---

## 5. Best Practices (Accumulated from Experience)

### 5.1 UI/UX
*   **Cupertino Only**: Never use Material widgets in presentation layer.
*   **Stack Layout**: Use `Stack` + `Positioned` for complex layouts (e.g., bottom-fixed buttons).
*   **Context Handling**: When using `CupertinoActionSheet`, rename builder context (e.g., `sheetContext`) to avoid conflicts with parent context.

### 5.2 Biometrics
*   **Detection**: Use `local_auth.getAvailableBiometrics()` to detect Face ID vs Touch ID.
*   **Fallback**: If specific type not detected, fall back to generic "Biometrics" text.

### 5.3 L10n
*   Always run `flutter gen-l10n` after modifying `.arb` files.
*   Create ARB keys immediately when adding new features.

### 5.4 Planning
*   Use `planning-with-files` skill for complex multi-step tasks.
*   Document findings in `.opencode/plans/findings.md`.

---

## 6. VaultNotifier Call Conventions

Most `VaultNotifier` methods require a `Ref ref` parameter. Always pass `ref` from the calling widget:

```dart
ref.read(vaultProvider.notifier).updateItem(item, ref);
ref.read(vaultProvider.notifier).deleteItem(id, ref);
ref.read(vaultProvider.notifier).addItemWithDetails(item, ref);
ref.read(vaultProvider.notifier).deleteSelectedItems(ref);
ref.read(vaultProvider.notifier).copyPassword(id, ref);
ref.read(vaultProvider.notifier).copyAllCredentials(id, l10n, ref);
ref.read(vaultProvider.notifier).checkInitialStatus(ref);
```

Internal helpers (`_saveAndRefresh`, `_startSyncWatch`) use the stored `_ref` field — do not add `Ref` parameters to them.

---

## 7. Pinyin Search & Sorting

*   `SearchVaultItemsUseCase` matches `item.title` and `item.titlePinyin`.
*   Search runs in an isolate via `compute(_searchVaultItemsInIsolate, ...)`.
*   `_searchVaultItemsInIsolate` **must** be a top-level function (not a method).
*   `SortService.sort(items)` handles pinyin-aware alphabetical ordering.

---

## 8. App Lock

Uses `flutter_app_lock` package. Import: `package:flutter_app_lock/flutter_app_lock.dart`.
Do **not** use a local `app_lock.dart` — the package is already in `pubspec.yaml`.
