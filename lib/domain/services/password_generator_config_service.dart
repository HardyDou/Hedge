import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/password_generator_config.dart';

/// 密码生成器配置服务
class PasswordGeneratorConfigService {
  static const String _key = 'password_generator_config';

  /// 保存配置
  static Future<void> saveConfig(PasswordGeneratorConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  /// 加载配置
  static Future<PasswordGeneratorConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);

    if (json == null) {
      return PasswordGeneratorConfig.defaultConfig();
    }

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      // 数据迁移：旧版本使用 numbersCount/symbolsCount 计数模式
      if (data.containsKey('numbersCount') || data.containsKey('symbolsCount')) {
        final migratedConfig = _migrateOldConfig(data);
        await saveConfig(migratedConfig);
        return migratedConfig;
      }

      // 旧版本（更早期）使用 includeUppercase/includeLowercase 等 bool 字段
      if (data.containsKey('includeUppercase') ||
          data.containsKey('includeLowercase') ||
          data.containsKey('includeNumbers') ||
          data.containsKey('includeSymbols')) {
        final migratedConfig = _migrateVeryOldConfig(data);
        await saveConfig(migratedConfig);
        return migratedConfig;
      }

      // 兜底：确保新字段存在，防止旧格式缺字段导致 null 类型错误
      data.putIfAbsent('includeNumbers', () => true);
      data.putIfAbsent('includeSymbols', () => true);
      return PasswordGeneratorConfig.fromJson(data);
    } catch (e) {
      await prefs.remove(_key);
      final defaultConfig = PasswordGeneratorConfig.defaultConfig();
      await saveConfig(defaultConfig);
      return defaultConfig;
    }
  }

  /// 迁移计数模式配置（numbersCount/symbolsCount → includeNumbers/includeSymbols）
  static PasswordGeneratorConfig _migrateOldConfig(Map<String, dynamic> oldData) {
    return PasswordGeneratorConfig(
      length: oldData['length'] as int? ?? 16,
      includeNumbers: (oldData['numbersCount'] as int? ?? 0) > 0,
      includeSymbols: (oldData['symbolsCount'] as int? ?? 0) > 0,
      excludeAmbiguous: oldData['excludeAmbiguous'] as bool? ?? false,
    );
  }

  /// 迁移更早期的 bool 字段配置
  static PasswordGeneratorConfig _migrateVeryOldConfig(Map<String, dynamic> oldData) {
    return PasswordGeneratorConfig(
      length: oldData['length'] as int? ?? 16,
      includeNumbers: oldData['includeNumbers'] as bool? ?? true,
      includeSymbols: oldData['includeSymbols'] as bool? ?? true,
      excludeAmbiguous: oldData['excludeAmbiguous'] as bool? ?? false,
    );
  }

  /// 清除配置（用于调试）
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
