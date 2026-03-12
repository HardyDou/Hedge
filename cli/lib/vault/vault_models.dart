/// VaultItem 模型（与主应用保持一致，去除 Flutter/lpinyin 依赖）
class VaultItem {
  final String id;
  final String title;
  final String? titlePinyin;
  final String? username;
  final String? password;
  final String? url;
  final String? notes;
  final String? category;
  final String? totpSecret;
  final String? totpIssuer;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultItem({
    required this.id,
    required this.title,
    this.titlePinyin,
    this.username,
    this.password,
    this.url,
    this.notes,
    this.category,
    this.totpSecret,
    this.totpIssuer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      title: json['title'] as String,
      titlePinyin: json['titlePinyin'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      totpSecret: json['totpSecret'] as String?,
      totpIssuer: json['totpIssuer'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
        'totpSecret': totpSecret,
        'totpIssuer': totpIssuer,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 搜索匹配（标题、URL、用户名）
  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        (url?.toLowerCase().contains(q) ?? false) ||
        (username?.toLowerCase().contains(q) ?? false) ||
        (notes?.toLowerCase().contains(q) ?? false);
  }
}

class Vault {
  final List<VaultItem> items;

  Vault({required this.items});

  factory Vault.fromJson(Map<String, dynamic> json) {
    return Vault(
      items: (json['items'] as List<dynamic>)
          .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
