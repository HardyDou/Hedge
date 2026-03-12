import '../auth/auth_manager.dart';

class ListCommand {
  final AuthManager authManager;

  ListCommand(this.authManager);

  Future<int> execute() async {
    final vault = await authManager.authenticate();
    if (vault == null) return 1;

    final items = await authManager.listItems();
    if (items.isEmpty) {
      print('No items found');
      return 0;
    }

    print('\nVault Items (${items.length}):');
    for (final item in items) {
      print('  • ${item.title}');
    }
    print('');

    return 0;
  }
}
