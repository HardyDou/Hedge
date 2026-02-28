import 'package:hedge/src/dart/vault.dart';

class CopyPasswordUseCase {
  String execute(VaultItem item) => item.password ?? '';
}
