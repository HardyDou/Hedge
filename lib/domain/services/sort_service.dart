import 'package:hedge/src/dart/vault.dart';

class SortService {
  static int compareVaultItems(VaultItem a, VaultItem b) {
    final aKey = _getSortKey(a.title);
    final bKey = _getSortKey(b.title);

    final aCategory = _getCategory(aKey);
    final bCategory = _getCategory(bKey);

    if (aCategory != bCategory) {
      return aCategory.compareTo(bCategory);
    }

    return aKey.compareTo(bKey);
  }

  static String _getSortKey(String title) {
    if (title.isEmpty) return '';
    return title[0];
  }

  static int _getCategory(String char) {
    if (char.isEmpty) return 2;
    final code = char.codeUnitAt(0);
    if (code >= 48 && code <= 57) return 0;
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) return 1;
    return 2;
  }

  static List<VaultItem> sort(List<VaultItem> items) {
    return List.from(items)..sort(compareVaultItems);
  }
}
