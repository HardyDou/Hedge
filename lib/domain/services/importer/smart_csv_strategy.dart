import 'package:csv/csv.dart';
import 'package:note_password/src/dart/vault.dart';
import 'import_strategy.dart';

class SmartCsvStrategy implements ImportStrategy {
  @override
  String get providerName => 'Smart Import';

  @override
  ImportResult parse(String content) {
    if (content.trim().isEmpty) return ImportResult();

    // Parse CSV with header row
    // Use default configuration: comma separator, double quote text delimiter
    // Remove const to avoid "Not a constant expression" error and ensure compatibility
    // Pass shouldParseNumbers: false to convert method to keep IDs as strings
    final rows = const CsvToListConverter().convert(content, eol: '\n', shouldParseNumbers: false);
    
    if (rows.isEmpty) return ImportResult();

    // 1. Header Analysis
    // We assume the first row *might* be headers.
    final firstRow = rows[0];
    final headers = firstRow.map((e) => e.toString().toLowerCase().trim()).toList();
    final headerMap = _analyzeHeaders(headers);

    final List<VaultItem> items = [];
    int successCount = 0;
    int failedCount = 0;
    
    // If mapped, skip header row. Otherwise start from 0.
    final startIndex = headerMap.isNotEmpty ? 1 : 0; 

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final item = _extractItem(row, headerMap, headers);
        if (item != null) {
          items.add(item);
          successCount++;
        } else {
          // If extracted item is null (e.g. empty fields), consider it failed/skipped
          failedCount++;
        }
      } catch (e) {
        // Skip malformed rows
        failedCount++;
        // avoid_print in production, but we need to catch it
      }
    }

    return ImportResult(success: successCount, failed: failedCount, items: items);
  }

  Map<String, int> _analyzeHeaders(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (_isSynonym(h, ['title', 'name', 'account', 'service', 'label', 'app'])) map['title'] = i;
      else if (_isSynonym(h, ['username', 'email', 'user', 'login', 'id'])) map['username'] = i;
      else if (_isSynonym(h, ['password', 'pass', 'key', 'secret'])) map['password'] = i;
      else if (_isSynonym(h, ['url', 'website', 'site', 'link', 'address', 'uri'])) map['url'] = i;
      else if (_isSynonym(h, ['note', 'notes', 'comment', 'extra', 'remarks', 'info', 'description'])) map['notes'] = i;
    }
    
    // Heuristic: If we found at least 2 known columns, assume headers exist
    // This prevents accidental mapping of data as headers
    if (map.length >= 2) return map;
    return {};
  }

  bool _isSynonym(String header, List<String> synonyms) {
    // Exact match or contains (for simple cases)
    // We trim and lowercase before calling this
    if (synonyms.contains(header)) return true;
    return synonyms.any((s) => header.contains(s));
  }

  VaultItem? _extractItem(List<dynamic> row, Map<String, int> map, List<String> headers) {
    String? getValue(int index) {
      if (index >= row.length) return null;
      final val = row[index].toString().trim();
      return val.isEmpty ? null : val;
    }

    String? title;
    String? username;
    String? password;
    String? url;
    String? notes;
    
    // Core Extraction
    if (map.isNotEmpty) {
      if (map.containsKey('title')) title = getValue(map['title']!);
      if (map.containsKey('username')) username = getValue(map['username']!);
      if (map.containsKey('password')) password = getValue(map['password']!);
      if (map.containsKey('url')) url = getValue(map['url']!);
      if (map.containsKey('notes')) notes = getValue(map['notes']!);

      // Extras Packing: append unknown columns to Notes
      final extraNotes = StringBuffer();
      for (var i = 0; i < row.length; i++) {
        if (!map.values.contains(i)) {
          // This column was not mapped
           final val = getValue(i);
           if (val != null && val.isNotEmpty) {
             // Try to use header name if available
             final colName = (i < headers.length) ? headers[i] : 'Column $i';
             extraNotes.writeln('$colName: $val');
           }
        }
      }
      
      if (extraNotes.isNotEmpty) {
        notes = notes == null ? extraNotes.toString() : '$notes\n\n--- Imported Extras ---\n$extraNotes';
      }

    } else {
        // Fallback: Default column order
        // Title, URL, Username, Password, Notes
        title = getValue(0);
        url = getValue(1);
        username = getValue(2);
        password = getValue(3);
        notes = getValue(4);
    }

    // Fallback Logic for Title: Title -> Domain -> Username -> Untitled
    if (title == null || title.isEmpty) {
        if (url != null && url.isNotEmpty) {
             try {
                // Handle incomplete URLs
                final urlToParse = url.contains('://') ? url : 'https://$url';
                final uri = Uri.parse(urlToParse);
                if (uri.host.isNotEmpty) {
                    title = uri.host;
                    if (title!.startsWith('www.')) title = title.substring(4);
                } else {
                    title = url; // Fallback if host is empty
                }
             } catch (_) {
                title = url;
             }
        } else if (username != null && username.isNotEmpty) {
            title = username;
        } else {
            title = 'Untitled';
        }
    }

    return VaultItem(
      title: title!,
      username: username,
      password: password,
      url: url,
      notes: notes,
    );
  }
}
