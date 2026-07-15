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
import 'core/routes/app_router.dart';
import 'core/services/auth_event_bus.dart';
import 'core/theme/app_theme.dart';
import 'features/account/presentation/bloc/account_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/colis/presentation/bloc/colis_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le handler background FCM est enregistré dans FcmService.init() — pas ici.
  GoogleFonts.config.allowRuntimeFetching = false;

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

  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Yobnate Colis';
  }

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
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
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<AccountBloc>()),
        BlocProvider(create: (_) => di.sl<ColisBloc>()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Yobnate Colis',
          theme: AppTheme.light(),
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
          home: const SplashPage(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
