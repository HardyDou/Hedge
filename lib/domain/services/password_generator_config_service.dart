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

      // 数据迁移：检查是否是旧版本配置
      if (data.containsKey('includeUppercase') ||
          data.containsKey('includeLowercase') ||
          data.containsKey('includeNumbers') ||
          data.containsKey('includeSymbols')) {
        // 旧版本配置，迁移到新版本
        return _migrateOldConfig(data);
      }

      return PasswordGeneratorConfig.fromJson(data);
    } catch (e) {
      // 如果解析失败，返回默认配置
      return PasswordGeneratorConfig.defaultConfig();
    }
  }

  /// 迁移旧版本配置到新版本
  static PasswordGeneratorConfig _migrateOldConfig(Map<String, dynamic> oldData) {
    final length = oldData['length'] as int? ?? 16;
    final includeNumbers = oldData['includeNumbers'] as bool? ?? true;
    final includeSymbols = oldData['includeSymbols'] as bool? ?? true;
    final excludeAmbiguous = oldData['excludeAmbiguous'] as bool? ?? false;

    // 根据旧配置生成合理的数量
    final numbersCount = includeNumbers ? 2 : 0;
    final symbolsCount = includeSymbols ? 2 : 0;

    return PasswordGeneratorConfig(
      length: length,
      numbersCount: numbersCount,
      symbolsCount: symbolsCount,
      excludeAmbiguous: excludeAmbiguous,
    );
  }
}
