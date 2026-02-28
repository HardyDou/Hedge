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
