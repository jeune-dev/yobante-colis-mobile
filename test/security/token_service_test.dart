import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/services/token_service.dart';

/// Faux stockage en mémoire — remplace FlutterSecureStorage pour les tests unitaires.
/// Utilise AppleOptions (renommage IOSOptions/MacOsOptions dans flutter_secure_storage ^10).
class _FakeStorage extends Fake implements FlutterSecureStorage {
  final _store = <String, String?>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

/// VULN-L03 : Tests de sécurité — TokenService
void main() {
  late _FakeStorage fakeStorage;
  late TokenService tokenService;

  setUp(() {
    fakeStorage = _FakeStorage();
    tokenService = TokenService(secureStorage: fakeStorage);
  });

  group('TokenService — Sécurité', () {
    // JWT valide : exp = 9999999999 (an 2286)
    const validToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjk5OTk5OTk5OTl9'
        '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    // JWT expiré : exp = 1 (1970-01-01)
    const expiredToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjF9'
        '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    test('isAuthenticated retourne false si aucun token', () async {
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne false si token vide', () async {
      await fakeStorage.write(key: 'jwt_token', value: '');
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne false si token expiré (VULN-M05)', () async {
      await fakeStorage.write(key: 'jwt_token', value: expiredToken);
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne true si token valide', () async {
      await fakeStorage.write(key: 'jwt_token', value: validToken);
      expect(await tokenService.isAuthenticated, true);
    });

    test('getValidToken efface le token expiré et retourne null (VULN-C04)', () async {
      await fakeStorage.write(key: 'jwt_token', value: expiredToken);
      final result = await tokenService.getValidToken();
      expect(result, isNull);
      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
    });

    test('getValidToken conserve le refresh token quand le jeton d\'accès expire', () async {
      await fakeStorage.write(key: 'jwt_token', value: expiredToken);
      await fakeStorage.write(key: 'refresh_token', value: 'some_refresh');

      expect(await tokenService.getValidToken(), isNull);
      expect(await fakeStorage.read(key: 'refresh_token'), 'some_refresh');
    });

    test('isAuthenticated reste vrai avec un jeton expiré si un refresh token existe', () async {
      await fakeStorage.write(key: 'jwt_token', value: expiredToken);
      await fakeStorage.write(key: 'refresh_token', value: 'some_refresh');
      expect(await tokenService.isAuthenticated, true);
    });

    test('clearToken supprime le token JWT et le refresh token', () async {
      await fakeStorage.write(key: 'jwt_token', value: validToken);
      await fakeStorage.write(key: 'refresh_token', value: 'some_refresh');

      await tokenService.clearToken();

      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
      expect(await fakeStorage.read(key: 'refresh_token'), isNull);
    });

    test('setToken null supprime le token (VULN-C03)', () async {
      await fakeStorage.write(key: 'jwt_token', value: validToken);
      await tokenService.setToken(null);
      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
    });
    test('setToken vide supprime le token', () async {
      await fakeStorage.write(key: 'jwt_token', value: validToken);
      await tokenService.setToken('');
      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
    });
  });

  group('TokenService — Expiration (VULN-M05)', () {
    String jwt(Map<String, dynamic> payload) {
      String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64(payload)}.sig';
    }

    int dans(Duration d) => DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

    test('jeton expirant dans moins de 30 s considéré comme expiré (marge réseau)', () async {
      await fakeStorage.write(key: 'jwt_token', value: jwt({'exp': dans(const Duration(seconds: 10))}));
      expect(await tokenService.getValidToken(), isNull);
    });

    test('jeton expirant dans plus de 30 s accepté', () async {
      final token = jwt({'exp': dans(const Duration(minutes: 5))});
      await fakeStorage.write(key: 'jwt_token', value: token);
      expect(await tokenService.getValidToken(), token);
    });

    test('jeton illisible traité comme expiré et effacé', () async {
      await fakeStorage.write(key: 'jwt_token', value: 'pas.un.jwt');
      expect(await tokenService.getValidToken(), isNull);
      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
      expect(await tokenService.isAuthenticated, false);
    });
  });

  group('TokenService — Refresh token', () {
    test('setRefreshToken écrit, puis null ou vide supprime', () async {
      await tokenService.setRefreshToken('r1');
      expect(await tokenService.getRefreshToken(), 'r1');
      await tokenService.setRefreshToken('');
      expect(await tokenService.getRefreshToken(), isNull);
      await tokenService.setRefreshToken('r2');
      await tokenService.setRefreshToken(null);
      expect(await tokenService.getRefreshToken(), isNull);
    });

    test('refresh token vide : pas de session', () async {
      await fakeStorage.write(key: 'refresh_token', value: '');
      expect(await tokenService.isAuthenticated, false);
    });
  });
}
