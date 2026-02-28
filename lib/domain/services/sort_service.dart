import 'package:hedge/src/dart/vault.dart';

class SortService {
  static int compareVaultItems(VaultItem a, VaultItem b) {
    final aCategory = _getCategory(a); // 传入 VaultItem
    final bCategory = _getCategory(b); // 传入 VaultItem

    if (aCategory != bCategory) {
      return aCategory.compareTo(bCategory);
    }

    // 使用预存储的拼音进行排序
    final aPinyin = a.titlePinyin ?? a.title.toLowerCase();
    final bPinyin = b.titlePinyin ?? b.title.toLowerCase();
    return aPinyin.compareTo(bPinyin);
  }

  /// 获取分类：0=数字, 1=字母(含拼音), 2=其他非字母数字
  static int _getCategory(VaultItem item) {
    final title = item.title;
    final titlePinyin = item.titlePinyin;

    // 1. 如果是数字开头，归类为数字
    if (title.isNotEmpty) {
      final code = title.codeUnitAt(0);
      if (code >= 48 && code <= 57) return 0; // 0-9
    }

    // 2. 检查其拼音首字母（只有在 titlePinyin 存在且有效时才判断为字母类别）
    if (titlePinyin != null && titlePinyin.isNotEmpty) {
      final firstSortChar = titlePinyin[0];
      final code = firstSortChar.codeUnitAt(0);
      if (code >= 97 && code <= 122) return 1; // a-z 字母 (拼音首字母)
    }

    return 2; // 其他 (包括中文标题的原始首字符，或拼音生成失败的情况)
  }

  static List<VaultItem> sort(List<VaultItem> items) {
    return List.from(items)..sort(compareVaultItems);
  }
}
