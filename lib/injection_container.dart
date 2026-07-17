import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/services/token_service.dart';
import 'core/services/auth_event_bus.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Account
import 'features/account/data/datasources/account_remote_datasource.dart';
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

Future<bool> _tryRefresh(Dio dio) async {
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
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (kDebugMode) debugPrint('[REQ] ${options.method} ${options.path}');
        final skip = options.extra['skipAuthInterceptor'] == true;
        if (!skip) {
          final token = await sl<TokenService>().getValidToken();
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

        if (e.response?.statusCode == 401 && e.requestOptions.extra['skipAuthInterceptor'] != true) {
          final refreshed = await _tryRefresh(dio);
          if (refreshed) {
            final token = await sl<TokenService>().getValidToken();
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final retry = await dio.fetch(e.requestOptions);
              return handler.resolve(retry);
            } catch (_) {}
          }
          await sl<TokenService>().clearToken();
          AuthEventBus.instance.emitLogout();
        }

        final isNetwork = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        final retries = e.requestOptions.extra['retryCount'] as int? ?? 0;
        if (isNetwork && retries < 2) {
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
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMe(sl()));
  sl.registerLazySingleton(() => ModifierInfoPersonnelles(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerFactory(() => AccountBloc(getMe: sl(), modifierInfoPersonnelles: sl(), changePassword: sl(), accountRepository: sl()));

  // ── COLIS ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ColisRemoteDataSource>(() => ColisRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ColisRepository>(() => ColisRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetColis(sl()));
  sl.registerLazySingleton(() => GetColisDetail(sl()));
  sl.registerLazySingleton(() => CreerColis(sl()));
  sl.registerLazySingleton(() => GetSuiviColis(sl()));
  sl.registerLazySingleton(() => AnnulerColis(sl()));
  sl.registerFactory(() => ColisBloc(
    getColis: sl(), getColisDetail: sl(), creerColis: sl(),
    getSuiviColis: sl(), annulerColis: sl(),
  ));

  // ── VILLES ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<VillesRemoteDataSource>(() => VillesRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<VillesRepository>(() => VillesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetVilles(sl()));
  sl.registerFactory(() => VillesBloc(getVilles: sl()));

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(() => NotificationsRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(sl()));
  sl.registerFactory(() => NotificationsBloc(repo: sl()));

  // ── PAIEMENTS ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PaiementsRemoteDataSource>(() => PaiementsRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<PaiementsRepository>(() => PaiementsRepositoryImpl(remoteDataSource: sl()));
  sl.registerFactory(() => PaiementsBloc(paiementsRepository: sl()));
}
