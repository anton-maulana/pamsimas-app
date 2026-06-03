// ─── Auth Model ───────────────────────────────────────────────────────────────

class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: (json['token_type'] as String?) ?? 'Bearer',
        expiresIn: (json['expires_in'] as int?) ?? 3600,
      );
}
