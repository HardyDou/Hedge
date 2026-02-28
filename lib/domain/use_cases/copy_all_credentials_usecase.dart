import 'package:hedge/src/dart/vault.dart';

class CredentialParts {
  final String? username;
  final String? password;
  final String? url;
  final String? notes;

  CredentialParts({this.username, this.password, this.url, this.notes});

  bool get isEmpty =>
      username == null &&
      password == null &&
      url == null &&
      notes == null;
}

class CopyAllCredentialsUseCase {
  CredentialParts execute(VaultItem item) {
    return CredentialParts(
      username: item.username,
      password: item.password,
      url: item.url,
      notes: item.notes,
    );
  }
}
