
import 'package:hedge/src/dart/vault.dart';

class SearchVaultItemsUseCase {
  Future<List<VaultItem>> execute(String query, List<VaultItem> items) async {
    if (query.isEmpty) {
      return items;
    }

    final lowerCaseQuery = query.toLowerCase();

    return items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(lowerCaseQuery);
      final pinyinMatch = item.titlePinyin?.toLowerCase().contains(lowerCaseQuery) ?? false;
      return titleMatch || pinyinMatch;
    }).toList();
  }
}
