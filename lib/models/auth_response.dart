import 'user_model.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel usuario;
  final int expiresIn;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
    this.expiresIn = 3600,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Backend structure: {"Tokens": {"AccessToken": ..., "RefreshToken": ...}, "Usuario": {...}}
    final tokens = json['Tokens'] ?? json['tokens'] ?? {};
    final usuario = json['Usuario'] ?? json['usuario'] ?? {};
    
    return AuthResponse(
      accessToken: tokens['AccessToken'] ?? tokens['accessToken'] ?? '',
      refreshToken: tokens['RefreshToken'] ?? tokens['refreshToken'] ?? '',
      expiresIn: tokens['ExpiresIn'] ?? tokens['expiresIn'] ?? 3600,
      usuario: UserModel.fromJson(usuario),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'usuario': usuario.toJson(),
    };
  }
}
