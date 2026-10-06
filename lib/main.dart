import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'core/config/env.dart';
import 'core/services/token_service.dart';
import 'core/i18n/langue.dart';
import 'core/routes/app_router.dart';
import 'core/services/auth_event_bus.dart';
import 'core/services/mesure_audience.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;
import 'core/widgets/adaptation_ecran.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le handler background FCM est enregistré dans FcmService.init() — pas ici.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Portrait sur téléphone, toutes orientations sur tablette
  await AdaptationEcran.configurerOrientation();

  try {
    await Firebase.initializeApp();
    if (!kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase non initialisé : $e');
  }

  // kIsWeb d'abord : dans un navigateur, Platform.* lève une exception.
  if (!kIsWeb && Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Yobante Colis';
  }

  await di.init();
  LangueApp.instance.initialiser(di.sl<SharedPreferences>());
  LangueApp.instance.enregistrerDansProfil = (langue) async {
    if (!await di.sl<TokenService>().isAuthenticated) return false;
    // Le compte n'enregistre que les langues connues du backend (400 sinon) : un
    // autre choix reste sur le téléphone, en attente, et prime à la connexion.
    if (!Env.languesDuCompte.contains(langue.code)) return false;
    await di.sl<Dio>().put(Env.clientProfil, data: {'langue': langue.code});
    return true;
  };
  MesureAudience.instance.demarrer();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _observateur = ObservateurAudience();
  late final StreamSubscription<void> _logoutSub;

  /// Plusieurs requêtes en 401 simultanées ne déclenchent qu'une déconnexion.
  bool _deconnexionForcee = false;

  @override
  void initState() {
    super.initState();
    _logoutSub = AuthEventBus.instance.onLogout.listen((_) {
      // La navigation suit LogoutSuccess (voir build) : accueil, puis connexion
      if (!mounted || _deconnexionForcee) return;
      _deconnexionForcee = true;
      di.sl<AuthBloc>().add(const LogoutRequested(ouvrirConnexion: true));
    });
  }

  @override
  void dispose() {
    _logoutSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => di.sl<AuthBloc>())],
      child: BlocListener<AuthBloc, AuthState>(
        bloc: di.sl<AuthBloc>(),
        listenWhen: (_, state) => state is LogoutSuccess,
        listener: (_, state) {
          // Déconnexion, quelle qu'en soit l'origine : la pile est vidée pour que
          // plus aucun écran ne garde les données du compte, et l'utilisateur
          // repart sur l'accueil en invité (il peut s'y reconnecter).
          _deconnexionForcee = false;
          final nav = _navigatorKey.currentState;
          if (nav == null) return;
          nav.pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false);
          if ((state as LogoutSuccess).ouvrirConnexion) nav.pushNamed(AppRouter.loginRoute);
        },
        child: ToastificationWrapper(
          child: ValueListenableBuilder<Langue>(
            valueListenable: LangueApp.instance,
            builder: (context, langue, _) => MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Yobante Colis',
              theme: AppTheme.light(),
              locale: langue.locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [for (final l in Langue.values) l.locale],
              home: const SplashPage(),
              onGenerateRoute: AppRouter.onGenerateRoute,
              navigatorObservers: [_observateur],
              // Taille de texte bornée et contenu centré sur tablette, pour tous les écrans
              builder: (context, child) => AdaptationEcran(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
