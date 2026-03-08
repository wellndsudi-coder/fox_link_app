/// Response from auth API containing access and refresh tokens.
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // seconds
  final String? uid;
  final String? email;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.uid,
    this.email,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: json['expires_in'] as int? ?? 3600,
      uid: json['uid'] as String?,
      email: json['email'] as String?,
    );
  }
}
