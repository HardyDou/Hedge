import 'package:hedge/src/dart/vault.dart';

class SortService {
  static int compareVaultItems(VaultItem a, VaultItem b) {
    final aCategory = _getCategory(a.title);
    final bCategory = _getCategory(b.title);

    if (aCategory != bCategory) {
      return aCategory.compareTo(bCategory);
    }

    // 使用预存储的拼音进行排序
    final aPinyin = a.titlePinyin ?? a.title.toLowerCase();
    final bPinyin = b.titlePinyin ?? b.title.toLowerCase();
    return aPinyin.compareTo(bPinyin);
  }

  /// 获取分类：0=数字, 1=字母, 2=中文及其他
  static int _getCategory(String title) {
    if (title.isEmpty) return 2;
    final code = title.codeUnitAt(0);
    if (code >= 48 && code <= 57) return 0; // 0-9
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) return 1; // A-Z, a-z
    return 2; // 中文及其他
  }

  static List<VaultItem> sort(List<VaultItem> items) {
    return List.from(items)..sort(compareVaultItems);
  }
}
