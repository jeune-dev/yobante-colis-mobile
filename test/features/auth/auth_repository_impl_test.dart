import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/core/errors/exceptions.dart';
import 'package:yobnate_colis/core/errors/failure.dart';
import 'package:yobnate_colis/core/services/token_service.dart';
import 'package:yobnate_colis/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:yobnate_colis/features/auth/data/models/user_model.dart';
import 'package:yobnate_colis/features/auth/data/repositories/auth_repository_impl.dart';

// ── Faux stockage en mémoire ──────────────────────────────────────────────────

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

// ── Faux datasource ───────────────────────────────────────────────────────────

class _FakeAuthDataSource extends Fake implements AuthRemoteDataSource {
  AuthResponseModel? loginResult;
  ServerException? loginError;
  bool logoutCalled = false;
  String? logoutAccessToken;

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> logout(String refreshToken, {String? accessToken}) async {
    logoutCalled = true;
    logoutAccessToken = accessToken;
  }

  @override
  Future<String> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
    String pays = 'SN',
    String? villeId,
    String? adresse,
    String typeCompte = 'particulier',
    String? raisonSociale,
    String? numeroIdentificationFiscale,
    String? numeroTvaIntracom,
    String? codePostal,
    String? codeParrainage,
  }) async => 'Compte créé.';

  @override
  Future<String> forgotPassword(String email) async => '';

  @override
  Future<String> resetPassword(
      String email, String code, String newPassword) async => '';
}

// ── Données de test ───────────────────────────────────────────────────────────

const _kValidToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjk5OTk5OTk5OTl9'
    '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

const _kRefreshToken = 'refresh_xyz';

final _kUser = UserModel(
  id: 'u1',
  nom: 'Diallo',
  prenom: 'Moussa',
  email: 'moussa@example.com',
  telephone: '771234567',
  role: 'client',
  accessToken: _kValidToken,
  refreshToken: _kRefreshToken,
);

final _kAuthResponse = AuthResponseModel(
  user: _kUser,
  accessToken: _kValidToken,
  refreshToken: _kRefreshToken,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeStorage fakeStorage;
  late _FakeAuthDataSource fakeDs;
  late TokenService tokenService;
  late AuthRepositoryImpl repo;

  setUp(() {
    fakeStorage = _FakeStorage();
    fakeDs = _FakeAuthDataSource();
    tokenService = TokenService(secureStorage: fakeStorage);
    repo = AuthRepositoryImpl(
      remoteDataSource: fakeDs,
      tokenService: tokenService,
      secureStorage: fakeStorage,
    );
  });

  group('AuthRepositoryImpl.login', () {
    test('succès — retourne Right(user) et persiste token + rôle', () async {
      fakeDs.loginResult = _kAuthResponse;

      final result = await repo.login('moussa@example.com', 'password123');

      expect(result, isA<Right>());
      result.fold((_) => fail('devait être Right'), (user) {
        expect(user.id, 'u1');
        expect(user.email, 'moussa@example.com');
      });
      expect(await fakeStorage.read(key: 'jwt_token'), _kValidToken);
      expect(await fakeStorage.read(key: 'refresh_token'), _kRefreshToken);
      expect(await fakeStorage.read(key: 'user_id'), 'u1');
      expect(await fakeStorage.read(key: 'user_role'), 'client');
    });

    test('ServerException — retourne Left(ServerFailure)', () async {
      fakeDs.loginError = const ServerException(message: 'Identifiants invalides');

      final result = await repo.login('x@x.com', 'wrong');

      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('devait être Left'),
      );
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('efface le token JWT, refresh, user_id et user_role', () async {
      await fakeStorage.write(key: 'jwt_token', value: _kValidToken);
      await fakeStorage.write(key: 'refresh_token', value: _kRefreshToken);
      await fakeStorage.write(key: 'user_id', value: 'u1');
      await fakeStorage.write(key: 'user_role', value: 'client');

      await repo.logout();

      expect(await fakeStorage.read(key: 'jwt_token'), isNull);
      expect(await fakeStorage.read(key: 'refresh_token'), isNull);
      expect(await fakeStorage.read(key: 'user_id'), isNull);
      expect(await fakeStorage.read(key: 'user_role'), isNull);
    });

    test('appelle le endpoint logout sur le backend si refresh token présent',
        () async {
      await fakeStorage.write(key: 'refresh_token', value: _kRefreshToken);

      await repo.logout();

      expect(fakeDs.logoutCalled, true);
    });

    test("joint le jeton d'accès pour qu'il soit révoqué", () async {
      await fakeStorage.write(key: 'jwt_token', value: _kValidToken);
      await fakeStorage.write(key: 'refresh_token', value: _kRefreshToken);

      await repo.logout();

      expect(fakeDs.logoutAccessToken, _kValidToken);
    });

    test('ne plante pas si aucun refresh token', () async {
      // Aucun token stocké
      await expectLater(repo.logout(), completes);
      expect(fakeDs.logoutCalled, false);
    });
  });
}
