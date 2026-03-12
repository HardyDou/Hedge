enum AuthMode { biometric, password }

class CliSession {
  final String tokenId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final AuthMode mode;

  CliSession({
    required this.tokenId,
    required this.issuedAt,
    required this.expiresAt,
    required this.mode,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'mode': mode.name,
      };

  factory CliSession.fromJson(Map<String, dynamic> json) {
    return CliSession(
      tokenId: json['tokenId'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      mode: AuthMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => AuthMode.password,
      ),
    );
  }
}
