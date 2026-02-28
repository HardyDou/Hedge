import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/importer/smart_csv_strategy.dart';

/// Strategy specifically optimized for Chrome exports.
/// Chrome format is fixed: name, url, username, password, note
class ChromeCsvStrategy extends SmartCsvStrategy {
  @override
  String get providerName => 'Google Chrome';
  
  // Chrome is standard enough that SmartCsvStrategy handles it perfectly.
  // We subclass just for the explicit provider name and potential future overrides.
}

/// Strategy for 1Password CSV exports.
class OnePasswordCsvStrategy extends SmartCsvStrategy {
  @override
  String get providerName => '1Password';

  // 1Password headers are also well covered by SmartCsvStrategy's synonym list.
  // (Title, Website, Username, Password, Notes)
}
