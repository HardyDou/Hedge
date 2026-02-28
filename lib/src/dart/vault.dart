import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:lpinyin/lpinyin.dart';
import 'package:uuid/uuid.dart';
import 'crypto.dart';

class VaultItem {
  final String id;
  final String title;
  final String? titlePinyin;
  final String? username;
  final String? password;
  final String? url;
  final String? notes;
  final String? category;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultItem({
    String? id,
    required this.title,
    String? titlePinyin,
    this.username,
    this.password,
    this.url,
    this.notes,
    this.category,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        titlePinyin = titlePinyin ?? _generatePinyin(title),
        attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 生成拼音（用于排序）
  static String _generatePinyin(String title) {
    if (title.isEmpty) return '';
    return PinyinHelper.getPinyinE(title, separator: '').toLowerCase();
  }

  VaultItem copyWith({
    String? id,
    String? title,
    String? titlePinyin,
    String? username,
    String? password,
    String? url,
    String? notes,
    String? category,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newTitle = title ?? this.title;
    return VaultItem(
      id: id ?? this.id,
      title: newTitle,
      titlePinyin: title != null ? _generatePinyin(newTitle) : (titlePinyin ?? this.titlePinyin),
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titlePinyin': titlePinyin,
        'username': username,
        'password': password,
        'url': url,
        'notes': notes,
        'category': category,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    // 懒加载迁移：历史数据缺失拼音时自动计算
    final titlePinyin = json['titlePinyin'] as String? ?? _generatePinyin(title);
    
    return VaultItem(
      id: json['id'] as String,
      title: title,
      titlePinyin: titlePinyin,
      username: json['username'] as String?,
      password: json['password'] as String?,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class Attachment {
  final String name;
  final Uint8List data;

  Attachment({required this.name, required this.data});

  Map<String, dynamic> toJson() => {
        'name': name,
        'data': base64Encode(data),
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        name: json['name'] as String,
        data: base64Decode(json['data'] as String),
      );
}

class Vault {
  final List<VaultItem> items;

  Vault({List<VaultItem>? items}) : items = items ?? [];

  Vault copyWith({List<VaultItem>? items}) {
    return Vault(items: items ?? this.items);
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Vault.fromJson(Map<String, dynamic> json) => Vault(
        items: (json['items'] as List<dynamic>)
            .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class VaultService {
  static Future<void> saveVault(String path, String password, Vault vault) async {
    final salt = CryptoService.generateSalt();
    final encrypted = await CryptoService.encryptJson(vault.toJson(), password, salt);
    await File(path).writeAsBytes(encrypted);
  }

  static Future<Vault> loadVault(String path, String password) async {
    final data = await File(path).readAsBytes();
    final json = await CryptoService.decryptJson(data, password);
    if (json == null) {
      throw Exception('Invalid password or corrupted vault file');
    }
    return Vault.fromJson(json);
  }

  static Vault createEmptyVault() => Vault();

  static Vault addItem(Vault vault, String title) {
    final item = VaultItem(title: title);
    return vault.copyWith(items: [...vault.items, item]);
  }

  static Vault addItemWithDetails(Vault vault, VaultItem item) {
    return vault.copyWith(items: [...vault.items, item]);
  }

  static Vault updateItem(Vault vault, VaultItem updatedItem) {
    final newItems = vault.items.map((item) {
      if (item.id == updatedItem.id) {
        return updatedItem;
      }
      return item;
    }).toList();
    return vault.copyWith(items: newItems);
  }

  static Vault deleteItem(Vault vault, String id) {
    return vault.copyWith(
      items: vault.items.where((i) => i.id != id).toList(),
    );
  }
}
