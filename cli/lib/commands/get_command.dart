import '../auth/auth_manager.dart';
import 'dart:io';

class GetCommand {
  final AuthManager authManager;

  GetCommand(this.authManager);

  Future<int> execute(String query, {String? field, bool noCopy = false}) async {
    final vault = await authManager.authenticate();
    if (vault == null) return 1;

    final item = await authManager.getItem(query);
    if (item == null) {
      print('❌ No item found matching "$query"');
      return 1;
    }

    String? value;
    switch (field) {
      case 'username':
        value = item.username;
        break;
      case 'password':
        value = item.password;
        break;
      case 'url':
        value = item.url;
        break;
      case 'notes':
        value = item.notes;
        break;
      default:
        value = item.password;
    }

    if (value == null || value.isEmpty) {
      print('❌ Field "${field ?? 'password'}" not found in item "${item.title}"');
      return 1;
    }

    if (noCopy) {
      print(value);
    } else {
      await _copyToClipboard(value);
      print('✓ Password copied to clipboard');
    }

    return 0;
  }

  Future<void> _copyToClipboard(String text) async {
    if (Platform.isMacOS) {
      final process = await Process.start('pbcopy', []);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    } else if (Platform.isLinux) {
      final process = await Process.start('xclip', ['-selection', 'clipboard']);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    }
  }
}
