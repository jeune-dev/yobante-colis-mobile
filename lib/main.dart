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
import 'core/i18n/langue.dart';
import 'core/routes/app_router.dart';
import 'core/services/auth_event_bus.dart';
import 'core/services/mesure_audience.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
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

  @override
  void initState() {
    super.initState();
    _logoutSub = AuthEventBus.instance.onLogout.listen((_) {
      if (mounted) {
        di.sl<AuthBloc>().add(LogoutRequested());
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
      }
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
    );
  }
}
