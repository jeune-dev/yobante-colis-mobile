import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Service de gestion du JWT.
/// Vérifie l'expiration du token côté client avant chaque requête.
/// Ne stocke jamais le mot de passe.
///
/// Le jeton d'accès vit 1 h ; le refresh token (7 jours) permet d'en obtenir un
/// nouveau. Une session reste donc ouverte tant qu'un refresh token est stocké,
/// même si le jeton d'accès a expiré : c'est l'intercepteur Dio qui le renouvelle.
class TokenService {
  final FlutterSecureStorage secureStorage;

  TokenService({required this.secureStorage});

  /// Vrai si une session existe : jeton d'accès valide, ou refresh token
  /// permettant d'en obtenir un nouveau.
  Future<bool> get isAuthenticated async {
    final token = await getToken();
    if (token != null && token.isNotEmpty && !_isTokenExpired(token)) return true;
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_token');
  }

  /// Retourne le token uniquement s'il est valide (non expiré).
  /// Un jeton expiré est supprimé, mais le refresh token est conservé pour
  /// permettre le renouvellement de la session.
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    if (_isTokenExpired(token)) {
      await secureStorage.delete(key: 'jwt_token');
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
