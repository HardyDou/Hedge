import 'package:note_password/src/dart/vault.dart';

class ImportResult {
  final int success;
  final int failed;
  final List<VaultItem> items;

  ImportResult({
    this.success = 0,
    this.failed = 0,
    this.items = const [],
  });
}

abstract class ImportStrategy {
  /// Parses the raw content and returns an ImportResult with items and counts.
  /// This should be pure Dart code suitable for running in an isolate.
  ImportResult parse(String content);
}
