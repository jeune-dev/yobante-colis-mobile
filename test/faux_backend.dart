import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yobante_colis/core/services/token_service.dart';
import 'package:yobante_colis/injection_container.dart';

/// Support des tests d'écran : l'application est montée avec ses vraies
/// dépendances ([init]), seul le serveur est remplacé par [FauxBackend].
/// Écrans, sources de données, intercepteur Dio et sérialisation sont donc
/// ceux de la production.

class StockageMemoire extends Fake implements FlutterSecureStorage {
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
  }) async => valeurs[key];

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
  }) async => valeurs.remove(key);
}

/// Faux serveur : chaque chemin (sans le préfixe /api/v1) reçoit la réponse de [routes] ;
/// un chemin non prévu répond 404. Les requêtes reçues sont gardées pour vérification.
class FauxBackend implements HttpClientAdapter {
  final requetes = <RequestOptions>[];
  final Map<String, FutureOr<(int, Object?)> Function(RequestOptions o)> routes = {};

  Iterable<RequestOptions> vers(String chemin) => requetes.where((r) => r.path == chemin);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requetes.add(options);
    final route = routes[options.path];
    final (statut, corps) = route == null
        ? (404, {'message': 'Route non simulée : ${options.path}'})
        : await route(options);
    return ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Réponse `{ success, data }` du backend.
(int, Object?) ok(Map<String, dynamic> data) => (200, {'success': true, 'data': data});

/// Prépare l'application (une fois par fichier) puis, à chaque test, un serveur
/// et un stockage vierges : visiteur non connecté par défaut.
class Environnement {
  late FauxBackend backend;
  // Une seule instance : les singletons de l'application (dépôts, services) la
  // conservent dès leur création ; elle est vidée avant chaque test.
  static final stockage = StockageMemoire();
  static bool _initialise = false;

  Future<void> preparer() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!_initialise) {
      SharedPreferences.setMockInitialValues({});
      await init();
      sl.allowReassignment = true;
      sl.registerLazySingleton<FlutterSecureStorage>(() => stockage);
      sl.registerLazySingleton(() => TokenService(secureStorage: stockage));
      _initialise = true;
    }
    stockage.valeurs.clear();
    backend = FauxBackend();
    sl<Dio>().httpClientAdapter = backend;
  }
}
