import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/services/auth_event_bus.dart';
import 'package:yobante_colis/core/services/token_service.dart';
import 'package:yobante_colis/injection_container.dart';

/// Tests de sécurité — intercepteur Dio de [init] (VULN-M05, VULN-C04).
///
/// Le client HTTP réellement utilisé par l'application est construit, puis
/// branché sur un faux backend : on vérifie qui reçoit le jeton, quand la
/// session est renouvelée et quand l'utilisateur est déconnecté.

String _jwt(int exp) {
  String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({'sub': 'u1', 'exp': exp})}.signature';
}

final _accesValide = _jwt(9999999999);
final _accesRenouvele = _jwt(9999999998);
final _accesExpire = _jwt(1);

class _Stockage extends Fake implements FlutterSecureStorage {
  final valeurs = <String, String>{};

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
      valeurs[key];

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
    if (value == null) {
      valeurs.remove(key);
    } else {
      valeurs[key] = value;
    }
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
    valeurs.remove(key);
  }
}

/// Faux backend : [repondre] décide du statut et du corps de chaque requête.
class _Backend implements HttpClientAdapter {
  final requetes = <RequestOptions>[];
  FutureOr<(int, Object?)> Function(RequestOptions o) repondre = (_) => (200, {'success': true});

  Iterable<RequestOptions> get refreshs => requetes.where((r) => r.path == Env.authRefresh);
  Iterable<RequestOptions> get metier => requetes.where((r) => r.path != Env.authRefresh);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // Copie : le rejeu modifie les en-têtes de la requête d'origine
    requetes.add(options.copyWith(headers: Map.of(options.headers)));
    final (statut, corps) = await repondre(options);
    return ResponseBody.fromString(jsonEncode(corps), statut, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Le refresh renvoie un nouveau couple de jetons (rotation).
(int, Object?) _refreshOk() => (200, {
      'data': {'accessToken': _accesRenouvele, 'refreshToken': 'refresh_2'},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late _Backend backend;
  late _Stockage stockage;
  late int deconnexions;
  late StreamSubscription<void> abonnement;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await init();
    sl.allowReassignment = true;
  });

  setUp(() {
    stockage = _Stockage();
    sl.registerLazySingleton(() => TokenService(secureStorage: stockage));
    backend = _Backend();
    dio = sl<Dio>()..httpClientAdapter = backend;
    deconnexions = 0;
    abonnement = AuthEventBus.instance.onLogout.listen((_) => deconnexions++);
  });

  tearDown(() => abonnement.cancel());

  String? bearer(RequestOptions o) => o.headers['Authorization'] as String?;

  group('envoi du jeton', () {
    test('le client vise l\'API de production en HTTPS', () {
      expect(dio.options.baseUrl, startsWith('https://'));
      expect(dio.options.baseUrl, Env.apiUrl);
    });

    test('jeton valide joint en Bearer', () async {
      stockage.valeurs['jwt_token'] = _accesValide;
      await dio.get('/client/colis');
      expect(bearer(backend.requetes.single), 'Bearer $_accesValide');
    });

    test('visiteur sans session : aucun en-tête Authorization', () async {
      await dio.get('/public/villes');
      expect(backend.requetes.single.headers.containsKey('Authorization'), isFalse);
    });

    test('jeton expiré sans refresh token : jamais envoyé, et effacé', () async {
      stockage.valeurs['jwt_token'] = _accesExpire;
      await dio.get('/public/villes');
      expect(backend.requetes.single.headers.containsKey('Authorization'), isFalse);
      expect(stockage.valeurs.containsKey('jwt_token'), isFalse);
    });

    test('jeton illisible traité comme expiré', () async {
      stockage.valeurs['jwt_token'] = 'pas.un.jwt';
      await dio.get('/public/villes');
      expect(backend.requetes.single.headers.containsKey('Authorization'), isFalse);
    });

    test('les requêtes marquées skipAuthInterceptor ne portent pas de jeton', () async {
      stockage.valeurs['jwt_token'] = _accesValide;
      await dio.get('/x', options: Options(extra: {'skipAuthInterceptor': true}));
      expect(backend.requetes.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('renouvellement de session', () {
    test('jeton expiré + refresh token : renouvelé AVANT l\'envoi, rotation stockée', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesExpire
        ..['refresh_token'] = 'refresh_1';
      backend.repondre = (o) => o.path == Env.authRefresh ? _refreshOk() : (200, {});

      await dio.get('/client/colis');

      final refresh = backend.refreshs.single;
      expect(refresh.data, {'refreshToken': 'refresh_1'});
      expect(refresh.headers.containsKey('Authorization'), isFalse,
          reason: 'Le refresh ne doit pas transporter l\'ancien jeton d\'accès');
      expect(bearer(backend.metier.single), 'Bearer $_accesRenouvele');
      expect(stockage.valeurs['jwt_token'], _accesRenouvele);
      expect(stockage.valeurs['refresh_token'], 'refresh_2');
    });

    test('401 avec session : refresh puis rejeu avec le nouveau jeton', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesValide
        ..['refresh_token'] = 'refresh_1';
      backend.repondre = (o) {
        if (o.path == Env.authRefresh) return _refreshOk();
        return bearer(o) == 'Bearer $_accesRenouvele' ? (200, {'ok': true}) : (401, {'message': 'Jeton révoqué'});
      };

      final res = await dio.get('/client/colis');

      expect(res.data, {'ok': true});
      expect(backend.refreshs, hasLength(1));
      expect(backend.metier.map(bearer), ['Bearer $_accesValide', 'Bearer $_accesRenouvele']);
      expect(deconnexions, 0);
    });

    test('401 simultanés : un seul refresh (le refresh token est à usage unique)', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesValide
        ..['refresh_token'] = 'refresh_1';
      backend.repondre = (o) async {
        if (o.path == Env.authRefresh) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _refreshOk();
        }
        return bearer(o) == 'Bearer $_accesRenouvele' ? (200, {}) : (401, {});
      };

      await Future.wait([dio.get('/a'), dio.get('/b'), dio.get('/c')]);

      expect(backend.refreshs, hasLength(1));
      expect(deconnexions, 0);
    });
  });

  group('déconnexion forcée', () {
    test('refresh refusé : jetons effacés et déconnexion émise', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesValide
        ..['refresh_token'] = 'refresh_vole';
      backend.repondre = (o) => (401, {'message': 'Session expirée'});

      await expectLater(dio.get('/client/colis'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(stockage.valeurs.containsKey('jwt_token'), isFalse);
      expect(stockage.valeurs.containsKey('refresh_token'), isFalse);
      expect(deconnexions, 1);
    });

    test('toujours 401 avec un jeton neuf (session révoquée) : déconnexion, pas de boucle', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesValide
        ..['refresh_token'] = 'refresh_1';
      backend.repondre = (o) => o.path == Env.authRefresh ? _refreshOk() : (401, {});

      await expectLater(dio.get('/client/colis'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(backend.metier, hasLength(2), reason: 'Un seul rejeu');
      expect(backend.refreshs, hasLength(1));
      expect(stockage.valeurs, isEmpty);
      expect(deconnexions, 1);
    });

    test('401 d\'un visiteur sans session : ni refresh ni déconnexion', () async {
      backend.repondre = (o) => (401, {});

      await expectLater(dio.get('/client/colis'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(backend.refreshs, isEmpty);
      expect(deconnexions, 0);
    });

    test('403 : pas de refresh ni de déconnexion', () async {
      stockage.valeurs
        ..['jwt_token'] = _accesValide
        ..['refresh_token'] = 'refresh_1';
      backend.repondre = (o) => (403, {'message': 'Interdit'});

      await expectLater(dio.get('/admin'), throwsA(isA<DioException>()));
      expect(backend.refreshs, isEmpty);
      expect(stockage.valeurs['refresh_token'], 'refresh_1');
      expect(deconnexions, 0);
    });
  });

  group('rejeu réseau', () {
    test('une création (POST) n\'est jamais rejouée après une coupure', () async {
      backend.repondre = (o) =>
          throw DioException(requestOptions: o, type: DioExceptionType.connectionError);

      await expectLater(dio.post('/client/colis', data: {'a': 1}), throwsA(isA<DioException>()));
      expect(backend.requetes, hasLength(1), reason: 'Un POST rejoué créerait l\'expédition en double');
    });

    test('une lecture (GET) est rejouée après une coupure', () async {
      var appels = 0;
      backend.repondre = (o) {
        if (appels++ == 0) throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
        return (200, {'ok': true});
      };

      final res = await dio.get('/public/villes');
      expect(res.data, {'ok': true});
      expect(backend.requetes, hasLength(2));
    });
  });
}
