import '../auth/auth_manager.dart';

class SearchCommand {
  final AuthManager authManager;

  SearchCommand(this.authManager);

  Future<int> execute(String query, {bool forceStandalone = false}) async {
    final vault = await authManager.authenticate(forceStandalone: forceStandalone);
    if (vault == null) return 1;

    final items = await authManager.listItems();
    final matches = items.where((item) => item.matches(query)).toList();

    if (matches.isEmpty) {
      print('No items found matching "$query"');
      return 0;
    }

    print('\nFound ${matches.length} item${matches.length > 1 ? 's' : ''}:');
    for (final item in matches) {
      print('  • ${item.title}');
    }
    print('');

    return 0;
  }
}
