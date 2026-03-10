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
        print('检测到旧配置，开始迁移: $data');
        final migratedConfig = _migrateOldConfig(data);
        print('迁移后配置: ${migratedConfig.toJson()}');
        // 立即保存迁移后的配置
        await saveConfig(migratedConfig);
        return migratedConfig;
      }

      // 新版本配置，但可能缺少字段，添加默认值
      if (!data.containsKey('numbersCount')) {
        data['numbersCount'] = 2;
      }
      if (!data.containsKey('symbolsCount')) {
        data['symbolsCount'] = 2;
      }

      final loaded = PasswordGeneratorConfig.fromJson(data);
      return _clampConfig(loaded);
    } catch (e) {
      // 如果解析失败，清除旧配置并返回默认配置
      print('配置解析失败: $e，使用默认配置');
      await prefs.remove(_key);
      final defaultConfig = PasswordGeneratorConfig.defaultConfig();
      await saveConfig(defaultConfig);
      return defaultConfig;
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

  /// 清除配置（用于调试）
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 确保 numbersCount + symbolsCount <= length
  static PasswordGeneratorConfig _clampConfig(PasswordGeneratorConfig config) {
    final maxTotal = config.length;
    final numbers = config.numbersCount.clamp(0, maxTotal);
    final symbols = config.symbolsCount.clamp(0, maxTotal - numbers);
    if (numbers == config.numbersCount && symbols == config.symbolsCount) {
      return config;
    }
    return config.copyWith(numbersCount: numbers, symbolsCount: symbols);
  }
}
