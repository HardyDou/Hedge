import 'package:hedge/src/dart/vault.dart';

class SortService {
  /// 排序规则：数字开头排最前，其余按拼音/字母混排
  static int compareVaultItems(VaultItem a, VaultItem b) {
    final aDigit = _isDigitStart(a.title);
    final bDigit = _isDigitStart(b.title);

    // 数字开头始终排最前
    if (aDigit != bDigit) return aDigit ? -1 : 1;

    // 同为数字或同为非数字：按排序键比较
    return _getSortKey(a).compareTo(_getSortKey(b));
  }

  static bool _isDigitStart(String title) {
    if (title.isEmpty) return false;
    final code = title[0].codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  /// 中文用 titlePinyin，英文用小写 title
  static String _getSortKey(VaultItem item) {
    if (item.title.isEmpty) return '';
    final code = item.title[0].codeUnitAt(0);
    if (code > 127) {
      // 中文字符：使用拼音排序键
      return item.titlePinyin ?? item.title.toLowerCase();
    }
    return item.title.toLowerCase();
  }

  static List<VaultItem> sort(List<VaultItem> items) {
    return List.from(items)..sort(compareVaultItems);
  }
}