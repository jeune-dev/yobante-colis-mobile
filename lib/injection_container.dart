import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/i18n/langue.dart';
import 'core/demo/demo_account_repository.dart';
import 'core/demo/demo_colis_repository.dart';
import 'core/demo/demo_config.dart';
import 'core/demo/demo_notifications_repository.dart';
import 'core/demo/demo_paiements_repository.dart';
import 'core/demo/demo_villes_repository.dart';
import 'core/services/token_service.dart';
import 'core/services/auth_event_bus.dart';
import 'core/services/mesure_audience.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Account
import 'features/account/data/datasources/account_remote_datasource.dart';
import 'features/account/data/datasources/espace_client_remote_datasource.dart';
import 'features/account/data/repositories/account_repository_impl.dart';
import 'features/account/domain/repositories/account_repository.dart';
import 'features/account/domain/usecases/get_me.dart';
import 'features/account/domain/usecases/modifier_info_personnelles.dart';
import 'features/account/domain/usecases/change_password.dart';
import 'features/account/presentation/bloc/account_bloc.dart';

// Colis
import 'features/colis/data/datasources/colis_remote_datasource.dart';
import 'features/colis/data/repositories/colis_repository_impl.dart';
import 'features/colis/domain/repositories/colis_repository.dart';
import 'features/colis/domain/usecases/colis_usecases.dart';
import 'features/colis/presentation/bloc/colis_bloc.dart';

// Catalogue
import 'features/catalogue/data/catalogue_remote_datasource.dart';

// Réclamations, adresses, enlèvements, avis
import 'features/reclamations/data/reclamations_remote_datasource.dart';
import 'features/adresses/data/adresses_remote_datasource.dart';
import 'features/enlevements/data/enlevements_remote_datasource.dart';
import 'features/avis/data/avis_remote_datasource.dart';

// Villes
import 'features/villes/data/datasources/villes_remote_datasource.dart';
import 'features/villes/data/repositories/villes_repository_impl.dart';
import 'features/villes/domain/repositories/villes_repository.dart';
import 'features/villes/domain/usecases/get_villes.dart';
import 'features/villes/presentation/bloc/villes_bloc.dart';

// Notifications
import 'features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

// Paiements
import 'features/paiements/data/datasources/paiements_remote_datasource.dart';
import 'features/paiements/data/repositories/paiements_repository_impl.dart';
import 'features/paiements/domain/repositories/paiements_repository.dart';
import 'features/paiements/presentation/bloc/paiements_bloc.dart';

final sl = GetIt.instance;

/// Rafraîchissement en cours, partagé par toutes les requêtes concurrentes : le
/// backend consomme le refresh token à chaque usage (rotation), deux appels
/// simultanés avec le même jeton feraient échouer le second et déconnecter.
Future<bool>? _refreshEnCours;

Future<bool> _tryRefresh(Dio dio) {
  return _refreshEnCours ??= _rafraichir(dio).whenComplete(() => _refreshEnCours = null);
}

Future<bool> _rafraichir(Dio dio) async {
  try {
    final refreshToken = await sl<TokenService>().getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    final response = await dio.post(
      Env.authRefresh,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    final newToken   = data?['accessToken'] as String?;
    final newRefresh = data?['refreshToken'] as String?;
    if (newToken == null || newToken.isEmpty) return false;
    await sl<TokenService>().setToken(newToken);
    if (newRefresh != null) await sl<TokenService>().setRefreshToken(newRefresh);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true), // ignore: deprecated_member_use
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ));

  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));

  // ── Dio ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (kDebugMode) debugPrint('[REQ] ${options.method} ${options.path}');
        // Identifiant anonyme de l'installation (conversion simulation → commande)
        options.headers['X-Visiteur-Id'] = MesureAudience.instance.visiteurId;
        // Le backend renvoie ses messages dans la langue de l'application
        options.headers['Accept-Language'] = LangueApp.instance.value.code;
        // Envoi de fichiers (jusqu'à 10 photos de 10 Mo) : délais adaptés aux
        // réseaux mobiles lents, au lieu des 30 s des requêtes ordinaires
        if (options.data is FormData) {
          options.sendTimeout = const Duration(minutes: 3);
          options.receiveTimeout = const Duration(minutes: 2);
        }
        final skip = options.extra['skipAuthInterceptor'] == true;
        if (!skip) {
          var token = await sl<TokenService>().getValidToken();
          // Jeton d'accès expiré mais session ouverte : renouvellement avant l'envoi
          if (token == null && (await sl<TokenService>().getRefreshToken())?.isNotEmpty == true) {
            if (await _tryRefresh(dio)) token = await sl<TokenService>().getValidToken();
          }
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (r, handler) {
        if (kDebugMode) debugPrint('[RES] ${r.statusCode} ${r.requestOptions.path}');
        handler.next(r);
      },
      onError: (e, handler) async {
        if (kDebugMode) debugPrint('[ERR] ${e.response?.statusCode} ${e.requestOptions.path}');

        final opts = e.requestOptions;
        if (e.response?.statusCode == 401 &&
            opts.extra['skipAuthInterceptor'] != true &&
            opts.extra['authRetried'] != true) {
          // Session sans refresh token (visiteur) : rien à renouveler, pas de déconnexion
          final aSession = (await sl<TokenService>().getRefreshToken())?.isNotEmpty == true ||
              opts.headers['Authorization'] != null;
          if (aSession) {
            if (await _tryRefresh(dio)) {
              final token = await sl<TokenService>().getValidToken();
              opts.headers['Authorization'] = 'Bearer $token';
              opts.extra['authRetried'] = true;
              try {
                return handler.resolve(await dio.fetch(opts));
              } on DioException catch (retryError) {
                // Toujours 401 avec un jeton neuf : session révoquée côté serveur
                if (retryError.response?.statusCode != 401) return handler.next(retryError);
              }
            }
            await sl<TokenService>().clearToken();
            AuthEventBus.instance.emitLogout();
          }
        }

        final isNetwork = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        // Seules les lectures sont rejouées : une création (POST) ou une modification
        // arrivée au serveur mais dont la réponse a tardé serait enregistrée deux
        // fois, et un formulaire multipart ne peut pas être renvoyé tel quel.
        final rejouable = opts.method == 'GET' || opts.method == 'HEAD';
        final retries = e.requestOptions.extra['retryCount'] as int? ?? 0;
        if (isNetwork && rejouable && retries < 2) {
          e.requestOptions.extra['retryCount'] = retries + 1;
          await Future.delayed(Duration(seconds: retries + 1));
          try {
            return handler.resolve(await dio.fetch(e.requestOptions));
          } catch (_) {}
        }

        handler.next(e);
      },
    ));
    return dio;
  });

  // ── AUTH ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    remoteDataSource: sl(),
    tokenService: sl(),
    secureStorage: sl(),
  ));
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));

  // ── ACCOUNT ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AccountRemoteDataSource>(() => AccountRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton(() => EspaceClientRemoteDataSource(dio: sl()));
  sl.registerLazySingleton<AccountRepository>(
      () => kDemoMode ? DemoAccountRepository() : AccountRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMe(sl()));
  sl.registerLazySingleton(() => ModifierInfoPersonnelles(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerFactory(() => AccountBloc(getMe: sl(), modifierInfoPersonnelles: sl(), changePassword: sl(), accountRepository: sl()));

  // ── COLIS ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ColisRemoteDataSource>(() => ColisRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ColisRepository>(
      () => kDemoMode ? DemoColisRepository() : ColisRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetColis(sl()));
  sl.registerLazySingleton(() => GetColisRecus(sl()));
  sl.registerLazySingleton(() => GetColisDetail(sl()));
  sl.registerLazySingleton(() => CreerColis(sl()));
  sl.registerLazySingleton(() => GetSuiviColis(sl()));
  sl.registerLazySingleton(() => AnnulerColis(sl()));
  sl.registerLazySingleton(() => RepondreProposition(sl()));
  sl.registerLazySingleton(() => ModifierColis(sl()));
  sl.registerFactory(() => ColisBloc(
    getColis: sl(), getColisRecus: sl(), getColisDetail: sl(), creerColis: sl(),
    getSuiviColis: sl(), annulerColis: sl(), repondreProposition: sl(), modifierColis: sl(),
  ));

  // ── CATALOGUE (données publiques) ─────────────────────────────────────────
  sl.registerLazySingleton(() => CatalogueRemoteDataSource(dio: sl()));

  // ── RÉCLAMATIONS (service après-vente) ─────────────────────────────────────
  sl.registerLazySingleton(() => ReclamationsRemoteDataSource(dio: sl()));

  // ── CARNET D'ADRESSES, ENLÈVEMENTS, AVIS ───────────────────────────────────
  sl.registerLazySingleton(() => AdressesRemoteDataSource(dio: sl()));
  sl.registerLazySingleton(() => EnlevementsRemoteDataSource(dio: sl()));
  sl.registerLazySingleton(() => AvisRemoteDataSource(dio: sl()));

  // ── VILLES ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<VillesRemoteDataSource>(() => VillesRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<VillesRepository>(
      () => kDemoMode ? DemoVillesRepository() : VillesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetVilles(sl()));
  sl.registerFactory(() => VillesBloc(getVilles: sl()));

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(() => NotificationsRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<NotificationsRepository>(
      () => kDemoMode ? DemoNotificationsRepository() : NotificationsRepositoryImpl(sl()));
  sl.registerFactory(() => NotificationsBloc(repo: sl()));

  // ── PAIEMENTS ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PaiementsRemoteDataSource>(() => PaiementsRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<PaiementsRepository>(
      () => kDemoMode ? DemoPaiementsRepository() : PaiementsRepositoryImpl(remoteDataSource: sl()));
  sl.registerFactory(() => PaiementsBloc(paiementsRepository: sl()));
}
