# Architecture v2.1 重构实施计划 (详细版)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 按照 Architecture Design v2.1 进行代码重构，**彻底移除 Material 依赖**，实现 100% Cupertino 原生体验。

**Alignment with AGENTS.md:**
- **Values:** Local-First, Zero-Knowledge, Native Experience (Cupertino).
- **Standards:** Follows `coding-standards.md` strictly.

**Architecture:** 
- 目录结构: mobile/ + desktop/ + shared/
- 业务逻辑: 提取到 Domain/Use Cases 层实现复用
- UI 规范: **100% Cupertino (No Material)**
- 性能优化: 加密操作使用 compute() 隔离到后台 Isolate

**Tech Stack:** Flutter, Riverpod, Cupertino Widgets, compute()

---

## 阶段 1: 目录结构重构

### Task 1.1: 创建 shared 目录并移动共享页面

**Files:**
- Modify: `lib/presentation/pages/page_factory.dart` (更新 import 路径，如果存在)
- Move: `lib/presentation/pages/mobile/unlock_page.dart` → `lib/presentation/pages/shared/unlock_page.dart`
- Move: `lib/presentation/pages/mobile/onboarding_page.dart` → `lib/presentation/pages/shared/onboarding_page.dart`
- Modify: `lib/main.dart` (更新 import 路径)

**Step 1: 创建 shared 目录**

```bash
mkdir -p lib/presentation/pages/shared
```

**Step 2: 移动文件**

```bash
mv lib/presentation/pages/mobile/unlock_page.dart lib/presentation/pages/shared/
mv lib/presentation/pages/mobile/onboarding_page.dart lib/presentation/pages/shared/
```

**Step 3: 更新 main.dart 的 import**

**Action:** 在 `lib/main.dart` 中查找并替换：
```dart
// Before
import 'package:note_password/presentation/pages/mobile/unlock_page.dart';
import 'package:note_password/presentation/pages/mobile/onboarding_page.dart';

// After
import 'package:note_password/presentation/pages/shared/unlock_page.dart';
import 'package:note_password/presentation/pages/shared/onboarding_page.dart';
```

**Step 4: 验证构建 & 生成代码**

```bash
flutter gen-l10n
flutter analyze
```
*Expected: No issues found.*

---

## 阶段 2: 彻底移除 Material (100% Cupertino)

### Task 2.1: 创建 AppThemeMode (替换 Material ThemeMode)

**Files:**
- Create: `lib/core/theme/app_theme_mode.dart`
- Modify: `lib/presentation/providers/theme_provider.dart`
- Modify: `lib/presentation/pages/desktop/settings_panel.dart`
- Modify: `lib/presentation/pages/mobile/settings_page.dart`
- Modify: `lib/main.dart`

**Step 1: 创建 AppThemeMode 枚举**

**Action:** 创建 `lib/core/theme/app_theme_mode.dart`:
```dart
enum AppThemeMode {
  system,
  light,
  dark,
}
```

**Step 2: 更新 ThemeProvider**

**Action:** 修改 `lib/presentation/providers/theme_provider.dart`:
1.  移除 `import 'package:flutter/material.dart';`
2.  导入 `import 'package:note_password/core/theme/app_theme_mode.dart';`
3.  将 `StateNotifier<ThemeMode>` 改为 `StateNotifier<AppThemeMode>`
4.  更新默认值为 `AppThemeMode.system`
5.  更新 `setThemeMode` 方法签名

**Step 3: 更新 main.dart 适配**

**Action:** 修改 `lib/main.dart`:
1.  移除 `import 'package:flutter/material.dart' show ThemeMode;`
2.  导入 `import 'package:note_password/core/theme/app_theme_mode.dart';`
3.  在 `build` 方法中手动映射 brightness:
```dart
// main.dart
final themeMode = ref.watch(themeProvider);
// ...
brightness: themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light, 
// 注意: system 模式需要根据系统实际 brightness 判断，但在 main.dart 顶层可能无法直接获取 system brightness。
// 修正策略: CupertinoThemeData 的 brightness 默认为 null (system)。
// 如果 themeMode == AppThemeMode.system，则 brightness = null。
// 如果 themeMode == AppThemeMode.light，则 brightness = Brightness.light。
// 如果 themeMode == AppThemeMode.dark，则 brightness = Brightness.dark。

brightness: themeMode == AppThemeMode.system 
    ? null 
    : (themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light),
```

### Task 2.2: 替换 Settings Panel 中的 ThemeMode

**Files:**
- Modify: `lib/presentation/pages/desktop/settings_panel.dart`
- Modify: `lib/presentation/pages/mobile/settings_page.dart`

**Action:**
1.  移除 `import 'package:flutter/material.dart';`
2.  导入 `import 'package:note_password/core/theme/app_theme_mode.dart';`
3.  将所有 `ThemeMode.system` 替换为 `AppThemeMode.system`
4.  将所有 `ThemeMode.light` 替换为 `AppThemeMode.light`
5.  将所有 `ThemeMode.dark` 替换为 `AppThemeMode.dark`

### Task 2.3: 替换 SelectableText (最佳实践)

**Files:**
- Modify: `lib/presentation/pages/mobile/detail_page.dart`
- Modify: `lib/presentation/pages/desktop/detail_panel.dart`

**Action:** 查找 `SelectableText` 并替换为 `CupertinoTextField`。

**Before:**
```dart
SelectableText(
  _item.notes!,
  style: TextStyle(...),
)
```

**After:**
```dart
CupertinoTextField(
  controller: TextEditingController(text: _item.notes),
  readOnly: true,
  maxLines: null, // 多行
  decoration: null, // 无边框
  padding: EdgeInsets.zero,
  style: TextStyle(
    color: isDark ? CupertinoColors.white : CupertinoColors.black,
    fontSize: 15,
  ),
  enableInteractiveSelection: true, // 允许选择复制
)
```
*注意: 需要在 build 方法中创建 controller，或者最好在 State 中维护 controller 以避免每次 build 都重建。对于简单的展示，每次 build 创建 controller 也是可接受的，只要 text 不经常变。*

### Task 2.4: 替换 Divider

**Files:**
- Modify: `lib/presentation/pages/mobile/settings_page.dart`

**Action:**
1.  移除 `import 'package:flutter/material.dart' show Divider;`
2.  查找 `Divider()`
3.  替换为:
```dart
Container(
  height: 0.5,
  color: CupertinoColors.separator, // Apple 标准分割线颜色
)
```

### Task 2.5: 重构 LargePasswordPage

**Files:**
- Modify: `lib/presentation/pages/mobile/large_password_page.dart`

**Action:**
1.  移除 `import 'package:flutter/material.dart';`
2.  将 `Scaffold` 替换为 `CupertinoPageScaffold`
3.  将 `AppBar` 替换为 `CupertinoNavigationBar`
4.  将 `Colors.white` 替换为 `CupertinoColors.white`
5.  将 `Icons.xxx` 替换为 `CupertinoIcons.xxx`

---

## 阶段 3: 功能逻辑复用 (Use Cases)

### Task 3.1: 创建 Use Cases

**Files:**
- Create: `lib/domain/use_cases/copy_password_usecase.dart`
- Create: `lib/domain/use_cases/copy_all_credentials_usecase.dart`

**Step 1: 创建 CopyPasswordUseCase**

```dart
class CopyPasswordUseCase {
  String execute(VaultItem item) => item.password ?? '';
}
```

**Step 2: 创建 CopyAllCredentialsUseCase**

```dart
class CredentialParts {
  final String? username;
  final String? password;
  final String? url;
  final String? notes;
  CredentialParts({this.username, this.password, this.url, this.notes});
}

class CopyAllCredentialsUseCase {
  CredentialParts execute(VaultItem item) {
    return CredentialParts(
      username: item.username,
      password: item.password,
      url: item.url,
      notes: item.notes,
    );
  }
}
```

### Task 3.2: 更新 VaultProvider

**Files:**
- Modify: `lib/presentation/providers/vault_provider.dart`

**Step 1: 实现 Provider 方法**

```dart
void copyPassword(String itemId) {
  final item = findItem(itemId);
  final password = _copyPasswordUseCase.execute(item);
  Clipboard.setData(ClipboardData(text: password));
}

void copyAllCredentials(String itemId, AppLocalizations l10n) {
  final item = findItem(itemId);
  final parts = _copyAllCredentialsUseCase.execute(item);
  
  final buffer = StringBuffer();
  if (parts.username != null && parts.username!.isNotEmpty) {
    buffer.writeln('${l10n.username}: ${parts.username}');
  }
  if (parts.password != null && parts.password!.isNotEmpty) {
    buffer.writeln('${l10n.password}: ${parts.password}');
  }
  if (parts.url != null && parts.url!.isNotEmpty) {
    buffer.writeln('${l10n.url}: ${parts.url}');
  }
  if (parts.notes != null && parts.notes!.isNotEmpty) {
    buffer.writeln('${l10n.notes}:\n${parts.notes}');
  }
  
  Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
}
```

### Task 3.3: 更新 UI 调用

**Files:**
- Modify: `lib/presentation/pages/mobile/detail_page.dart`
- Modify: `lib/presentation/pages/desktop/detail_panel.dart`

**Action:**
1.  移除 `_copyAll` 和 `_copyToClipboard` 方法
2.  将按钮点击事件改为调用 `ref.read(vaultProvider.notifier).copyPassword(...)`

---

## 阶段 4: Background Isolates

### Task 4.1: 重构 CryptoService 使用 compute()

**Files:**
- Modify: `lib/src/dart/crypto.dart`

**Action:**

1.  导入 `import 'package:flutter/foundation.dart';`
2.  定义参数类 `_EncryptParams`, `_DecryptParams`, `_DeriveKeyParams`
3.  定义**顶层函数** `_deriveKeyIsolate`, `_encryptDataIsolate`, `_decryptDataIsolate`
4.  修改 `CryptoService` 方法使用 `compute(topLevelFunction, params)`

*(详细代码参考 Task 4.1 之前的版本，此处略以保持简洁，但执行时需完整)*

---

## 阶段 5: Bug 修复

### Task 5.1: 修复 macOS 菜单 Bug

**Files:**
- Modify: `lib/presentation/pages/desktop/desktop_home_page.dart`

**Action:** 在 `_setupMenuChannel` 的 switch case 中添加 `break;`。

---

## 阶段 6: 最终验证 (Final Verification)

### Task 6.1: Material 零依赖验证

**Step 1: 严格 grep 检查**

```bash
# 检查除了 main.dart (Localizations 需要) 之外的所有文件
grep -r "package:flutter/material.dart" lib/ | grep -v "main.dart"
```

**Expected Result:** **无输出**。这意味着我们成功移除了所有业务代码中的 Material 依赖。

**Step 2: 运行测试**

```bash
flutter test
```

**Step 3: 构建检查**

```bash
flutter build ios --simulator --no-codesign
```

---

## 执行顺序

1. 阶段 1: 目录结构重构
2. 阶段 5: Bug 修复 (优先)
3. 阶段 2: 彻底移除 Material (100% Cupertino)
4. 阶段 3: 功能逻辑复用
5. 阶段 4: Background Isolates
6. 阶段 6: 最终验证
