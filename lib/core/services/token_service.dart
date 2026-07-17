import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Service de gestion du JWT.
/// Vérifie l'expiration du token côté client avant chaque requête.
/// Ne stocke jamais le mot de passe.
class TokenService {
  final FlutterSecureStorage secureStorage;

  TokenService({required this.secureStorage});

  /// Vérifie qu'un token existe ET qu'il n'est pas expiré.
  Future<bool> get isAuthenticated async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    return !_isTokenExpired(token);
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_token');
  }

  /// Retourne le token uniquement s'il est valide (non expiré).
  /// Supprime automatiquement le token si expiré.
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    if (_isTokenExpired(token)) {
      await clearToken();
      return null;
    }
    return token;
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: 'jwt_token');
    } else {
      await secureStorage.write(key: 'jwt_token', value: token);
    }
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  Future<String?> getRefreshToken() async =>
      secureStorage.read(key: 'refresh_token');

  Future<void> setRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: 'refresh_token');
    } else {
      await secureStorage.write(key: 'refresh_token', value: token);
    }
  }

  /// Vérifie l'expiration du JWT côté client.
  /// Considère le token expiré 30 secondes avant l'expiration réelle (marge réseau).
  bool _isTokenExpired(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'];
      if (exp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now()
          .isAfter(expiryDate.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}
