import 'package:flutter/foundation.dart';
import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/importer/smart_csv_strategy.dart';

class CsvImportService {
  final ImportStrategy _strategy;

  CsvImportService({ImportStrategy? strategy}) 
      : _strategy = strategy ?? SmartCsvStrategy();

  Future<ImportResult> import(String content) async {
    try {
      // Run parsing in a background isolate to avoid blocking the UI
      // compute() spawns an isolate and runs the callback function
      return await compute(_parseContent, content);
    } catch (e) {
      debugPrint('Import error: $e');
      // If the isolate fails completely (e.g. OOM), return a failure result
      return ImportResult(success: 0, failed: 1, items: []);
    }
  }
}

// Top-level function for compute. 
// Must be top-level or static to be passed to compute.
ImportResult _parseContent(String content) {
  // We instantiate the strategy here because we can't easily pass it 
  // unless it's a simple sendable object. 
  // Since SmartCsvStrategy logic is stateless (except for method local vars), this is fine.
  final strategy = SmartCsvStrategy();
  return strategy.parse(content);
}
