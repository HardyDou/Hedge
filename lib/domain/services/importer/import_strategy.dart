import 'package:hedge/src/dart/vault.dart';

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
  /// The display name of the strategy (e.g., "Google Chrome", "Smart Import")
  String get providerName;

  /// Parses the raw content and returns an ImportResult with items and counts.
  /// This should be pure Dart code suitable for running in an isolate.
  ImportResult parse(String content);
}
