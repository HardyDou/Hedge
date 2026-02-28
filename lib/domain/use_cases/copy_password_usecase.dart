import 'package:note_password/src/dart/vault.dart';

class CopyPasswordUseCase {
  String execute(VaultItem item) => item.password ?? '';
}
