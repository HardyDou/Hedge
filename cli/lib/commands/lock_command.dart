import '../session/session_storage.dart';

class LockCommand {
  Future<int> execute() async {
    await SessionStorage.clearSession();
    print('✓ CLI session locked. Next command will require authentication.');
    return 0;
  }
}
