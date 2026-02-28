# 技术方案文档：密码列表排序与字母索引

**Version**: 1.0
**Date**: 2026-02-28
**Status**: Draft

---

## 1. 技术选型

| 组件 | 方案 | 理由 |
|------|------|------|
| 拼音排序 | `intl` package | 官方推荐，稳定可靠 |
| 字母索引 | CustomScrollView + 手写索引组件 | 原生 Flutter 组件，定制性强 |
| 排序触发 | 在 VaultProvider getter 中触发 | 数据层统一处理 |
| Collator | 静态单例 | 避免重复创建开销 |

---

## 2. 核心实现

### 2.1 排序服务 (SortService)

```dart
import 'package:intl/intl.dart';

class SortService {
  static final Collator _collator = Intl.collator();
  
  /// 排序比较函数
  static int compareVaultItems(VaultItem a, VaultItem b) {
    final aChar = _getSortKey(a.title);
    final bChar = _getSortKey(b.title);
    
    // 分类：数字、字母、中文
    final aCategory = _getCategory(aChar);
    final bCategory = _getCategory(bChar);
    
    // 不同类别按顺序排序
    if (aCategory != bCategory) {
      return aCategory.compareTo(bCategory);
    }
    
    // 同类别按拼音/字母顺序
    return _collator.compare(aChar, bChar);
  }
  
  /// 获取排序键（提取首字符）
  static String _getSortKey(String title) {
    if (title.isEmpty) return '';
    return title[0];
  }
  
  /// 获取类别：0=数字, 1=字母, 2=中文
  static int _getCategory(String char) {
    if (char.isEmpty) return 2;
    final code = char.codeUnitAt(0);
    if (code >= 48 && code <= 57) return 0; // 0-9
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) return 1; // A-Z, a-z
    return 2; // 中文及其他
  }
}
```

### 2.2 VaultProvider 集成

```dart
// 在 VaultProvider 中添加排序后的 items Getter
List<VaultItem> get sortedItems {
  final items = vault?.items ?? [];
  return List.from(items)..sort(SortService.compareVaultItems);
}
```

### 2.3 移动端字母索引

```dart
class AlphabetIndexBar extends StatelessWidget {
  final List<String> letters; // 可用字母列表
  final Function(String) onLetterTap;
  
  // 使用 GestureDetector 捕获手势
  // 使用 RawGestureDetector + excludeFromSemantics 避免手势冲突
  // 显示放大镜覆盖层使用 Stack + AnimatedOpacity
}
```

---

## 3. 修改文件清单

| 文件 | 修改内容 | 优先级 |
|------|----------|--------|
| `pubspec.yaml` | 添加 `intl` 依赖 | P0 |
| `lib/domain/services/sort_service.dart` | 新建排序服务 | P0 |
| `lib/presentation/providers/vault_provider.dart` | 集成排序逻辑 | P0 |
| `lib/main.dart` | 移动端列表添加索引 | P0 |
| `lib/presentation/pages/desktop/desktop_home_page.dart` | 桌面端应用排序 | P0 |

---

## 4. 性能优化

### 4.1 Collator 复用
- 使用静态单例避免每次排序都创建 Collator 实例
- Collator 创建有约 10ms 开销，复用可显著提升性能

### 4.2 列表优化
- 使用 ListView.builder 懒加载
- 排序在 getter 中完成，不存储额外数据
- 使用 const constructor 减少重建

### 4.3 索引优化
- 索引项动态生成（只显示列表中实际存在的首字母）
- 手势响应使用门控避免频繁触发

---

## 5. 风险与应对

| 风险 | 应对措施 |
|------|----------|
| 拼音排序性能 | Collator 静态单例 |
| iOS 手势冲突 | excludeFromSemantics |
| 列表滚动位置丢失 | 使用 Key 保持状态 |

---

## 6. 测试计划

### 6.1 单元测试
- SortService 排序逻辑测试
- 数字、字母、中文混合排序测试

### 6.2 集成测试
- 列表显示顺序验证
- 索引跳转准确性验证

---

## 7. 验收标准

- [ ] 数字开头标题排在最前面
- [ ] 英文字母按 A-Z 排列
- [ ] 中文按拼音排列
- [ ] 移动端索引只在 >=20 条时显示
- [ ] 索引手势响应流畅
- [ ] 1000 条数据排序 < 100ms
