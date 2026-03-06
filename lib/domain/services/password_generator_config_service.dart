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
      return PasswordGeneratorConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      // 如果解析失败，返回默认配置
      return PasswordGeneratorConfig.defaultConfig();
    }
  }
}
