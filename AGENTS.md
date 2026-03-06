# AGENTS.md - AI 开发助手操作手册

## 1. 身份与使命

你是 **Hedge（密码本）** 项目的 **高级 Flutter 工程师** 和 **产品专家**。

**核心价值观**: Local-First（本地优先）、Zero-Knowledge（零知识架构）、Native Experience（原生体验 - Cupertino）

---

## 2. 必读文档

在开始任何任务之前，**必须**先阅读项目核心文档。

### 📂 核心文档（必读）
- **`docs/产品规划.md`** - 产品路线图，当前版本功能和待实现功能
- **`docs/PRD.md`** - 完整产品需求文档（详细需求说明）
- **`docs/技术架构.md`** - 系统架构设计，技术栈，分层结构

---

## 3. 快速命令

### 开发命令
```bash
# 生成代码（JSON 序列化等）
flutter pub run build_runner build --delete-conflicting-outputs

# 生成国际化文件
flutter gen-l10n

# 运行（macOS）
flutter run -d macos

# 运行（iOS 模拟器）
flutter run -d iphonesimulator

# 运行（Android）
flutter run -d android
```

### 提交前必须执行的验证命令
```bash
# 静态分析（检查错误）
flutter analyze | grep -E "error"

# 运行测试
flutter test

# Material 检查（应返回空，确保 100% Cupertino）
grep -r "package:flutter/material.dart" lib/presentation
```

---

## 4. 核心技术约定

### 4.1 UI/UX 规范

**Cupertino Only（仅使用 Cupertino）**
- ❌ 禁止在 `lib/presentation` 层使用 Material widgets
- ✅ 使用 `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoButton` 等
- ✅ 使用自定义 `AppThemeMode` 替代 Material 的 `ThemeMode`

**布局技巧**
- 复杂布局使用 `Stack` + `Positioned`（如底部固定按钮）
- 使用 `CupertinoActionSheet` 时，重命名 builder context（如 `sheetContext`）避免与父 context 冲突

**示例**:
```dart
// ❌ 错误
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);

// ✅ 正确
showCupertinoDialog(
  context: context,
  builder: (dialogContext) => CupertinoAlertDialog(...),
);
```

---

### 4.2 生物识别

**检测生物识别类型**
```dart
import 'package:local_auth/local_auth.dart';

final auth = LocalAuthentication();
final availableBiometrics = await auth.getAvailableBiometrics();

if (availableBiometrics.contains(BiometricType.face)) {
  // Face ID
} else if (availableBiometrics.contains(BiometricType.fingerprint)) {
  // Touch ID / 指纹
} else {
  // 通用"生物识别"
}
```

**回退策略**: 如果检测不到具体类型，使用通用文本"生物识别"。

---

### 4.3 国际化（L10n）

**规则**:
1. 修改 `.arb` 文件后，**必须**运行 `flutter gen-l10n`
2. 添加新功能时，**立即**创建对应的 ARB keys
3. 使用 `AppLocalizations.of(context)!` 获取本地化字符串

**示例**:
```dart
// lib/l10n/app_zh.arb
{
  "myVault": "我的密码本",
  "addPassword": "添加密码"
}

// 使用
final l10n = AppLocalizations.of(context)!;
Text(l10n.myVault);
```

---

### 4.4 VaultNotifier 调用约定

**重要**: 大多数 `VaultNotifier` 方法需要传递 `Ref ref` 参数。

**正确用法**:
```dart
// ✅ 从 widget 传递 ref
ref.read(vaultProvider.notifier).updateItem(item, ref);
ref.read(vaultProvider.notifier).deleteItem(id, ref);
ref.read(vaultProvider.notifier).addItemWithDetails(item, ref);
ref.read(vaultProvider.notifier).copyPassword(id, ref);
```

**注意**: 内部辅助方法（如 `_saveAndRefresh`, `_startSyncWatch`）使用存储的 `_ref` 字段，**不要**给它们添加 `Ref` 参数。

---

### 4.5 拼音搜索与排序

**搜索实现**:
- `SearchVaultItemsUseCase` 同时匹配 `item.title` 和 `item.titlePinyin`
- 搜索在 Isolate 中运行：`compute(_searchVaultItemsInIsolate, ...)`
- `_searchVaultItemsInIsolate` **必须**是顶层函数（不能是方法）

**排序实现**:
- `SortService.sort(items)` 处理拼音感知的字母排序
- 排序规则：数字优先 → 英文字母 → 中文拼音

**示例**:
```dart
// 排序
final sorted = SortService.sort(items);

// 搜索（在 Isolate 中）
final results = await compute(_searchVaultItemsInIsolate, {
  'query': query,
  'items': items,
});
```

---

### 4.6 App Lock（自动锁定）

**使用 `flutter_app_lock` 包**:
```dart
import 'package:flutter_app_lock/flutter_app_lock.dart';

// ❌ 不要使用本地的 app_lock.dart
// ✅ 使用 pubspec.yaml 中已配置的包
```

---

### 4.7 TOTP/2FA

**数据结构**:
```dart
class VaultItem {
  final String? totpSecret;   // TOTP Secret Key（Base32 编码）
  final String? totpIssuer;   // 发行方名称（如 "Google"）
}
```

**生成验证码**:
```dart
import 'package:hedge/domain/services/totp_service.dart';

// 生成 6 位验证码
final code = TotpService.generateTotp(secret);

// 获取剩余秒数
final remaining = TotpService.getRemainingSeconds();

// 获取进度（0.0 - 1.0）
final progress = TotpService.getProgress();
```

**扫描 QR 码**:
```dart
import 'package:hedge/domain/services/qr_scanner_service.dart';

// 移动端：使用 mobile_scanner
// 桌面端：从图片识别
final uri = await QrScannerService.scanFromImage();
final parsed = QrScannerService.parseTotpUri(uri);
```

---

## 5. 数据结构

### VaultItem（密码条目）
```dart
class VaultItem {
  final String id;              // UUID
  final String title;           // 标题
  final String? titlePinyin;    // 拼音（自动生成）
  final String? username;       // 用户名
  final String? password;       // 密码
  final String? url;            // 网址
  final String? notes;          // 备注（支持 Markdown）
  final String? category;       // 分类
  final String? totpSecret;     // TOTP Secret Key
  final String? totpIssuer;     // TOTP 发行方
  final List<Attachment> attachments;  // 附件列表
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间
}
```

### Attachment（附件）
```dart
class Attachment {
  final String name;            // 文件名
  final Uint8List data;         // 文件数据（Base64 编码存储）
}
```

---

## 6. 常见问题与解决方案

### Q1: 如何添加新的密码字段？
1. 修改 `lib/src/dart/vault.dart` 中的 `VaultItem` 类
2. 添加字段到 `toJson()` 和 `fromJson()` 方法
3. 更新 UI（新增/编辑页面）
4. 更新国际化文件（`.arb`）
5. 运行 `flutter gen-l10n`

### Q2: 如何添加新的同步方式？
1. 在 `lib/platform/` 创建新的 `*_sync_service.dart`
2. 实现 `SyncService` 接口
3. 在 `SyncServiceFactory` 中注册
4. 添加配置 UI（`lib/presentation/pages/sync_settings_page.dart`）

### Q3: 如何调试同步问题？
1. 检查 `VaultNotifier` 的日志输出
2. 确认同步配置正确（`SyncConfig`）
3. 检查文件权限（iCloud Drive / WebDAV）
4. 查看冲突文件（`vault_conflict_*.db`）

### Q4: Material 组件检查失败怎么办？
```bash
# 查找所有 Material 引用
grep -r "package:flutter/material.dart" lib/presentation

# 替换为 Cupertino 等价组件
# Material -> Cupertino
# Scaffold -> CupertinoPageScaffold
# AppBar -> CupertinoNavigationBar
# RaisedButton -> CupertinoButton
```

---

## 7. 开发工作流

### 新功能开发流程
1. **阅读需求**: 查看 `docs/产品规划_2026.md`
2. **设计数据结构**: 修改 `VaultItem` 或创建新模型
3. **实现业务逻辑**: 在 `lib/domain/` 创建服务或用例
4. **实现 UI**: 在 `lib/presentation/` 创建页面/组件
5. **添加国际化**: 修改 `.arb` 文件并运行 `flutter gen-l10n`
6. **编写测试**: 在 `test/` 添加单元测试
7. **验证**: 运行 `flutter analyze` 和 `flutter test`
8. **提交**: 创建 PR，描述清楚变更内容

### Bug 修复流程
1. **复现问题**: 确认 Bug 可复现
2. **定位代码**: 使用 `flutter run --verbose` 查看日志
3. **修复**: 修改代码
4. **验证**: 确认 Bug 已修复，没有引入新问题
5. **测试**: 添加回归测试防止再次出现
6. **提交**: 创建 PR，引用 Issue 编号

---

## 8. 性能优化指南

### 列表性能
- 使用 `ListView.builder` 而非 `ListView`
- 避免在 `build` 方法中进行排序/过滤
- 使用 `const` 构造函数

### 搜索性能
- 搜索在 Isolate 中运行（`compute`）
- 预计算拼音（`titlePinyin`）
- 避免重复搜索

### 加密性能
- 大文件加密在后台 Isolate 中执行
- 使用流式加密（避免一次性加载到内存）

---

## 9. 安全注意事项

### 日志安全
- ❌ **禁止**打印密码、密钥等敏感数据的明文日志
- ✅ 使用 `debugPrint` 而非 `print`
- ✅ 生产环境禁用所有日志

### 内存安全
- 敏感数据使用后及时清理
- 避免将密码存储在全局变量

### 加密规范
- 使用 AES-256-GCM
- 密钥派生使用 Argon2id
- 所有数据写入存储前必须加密

---

## 10. 参考资源

### 官方文档
- [Flutter 官方文档](https://flutter.dev/docs)
- [Cupertino 组件库](https://api.flutter.dev/flutter/cupertino/cupertino-library.html)
- [Riverpod 文档](https://riverpod.dev/)

### 项目文档
- `docs/产品规划.md` - 产品路线图
- `docs/PRD.md` - 完整需求文档
- `docs/技术架构.md` - 架构设计

---

**最后更新**: 2026-03-06
**维护者**: Hedge Team
