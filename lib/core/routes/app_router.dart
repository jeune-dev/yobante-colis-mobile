import 'package:flutter/material.dart';
import '../services/auth_status.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/client_home_page.dart';
import '../../features/expedition/presentation/pages/assistant_expedition_page.dart';
import '../../features/colis/presentation/pages/detail_colis_page.dart';
import '../../features/colis/presentation/pages/suivi_colis_page.dart';

class AppRouter {
  static const String splashRoute         = '/';
  static const String onboardingRoute     = '/onboarding';
  static const String loginRoute          = '/login';
  static const String registerRoute       = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute  = '/reset-password';
  static const String clientRoute         = '/client';
  static const String creationColisRoute  = '/colis/nouveau';
  static const String detailColisRoute    = '/colis/detail';
  static const String suiviColisRoute     = '/colis/suivi';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return _page(const SplashPage(), settings);
      case onboardingRoute:
        return _page(const OnboardingPage(), settings);
      case loginRoute:
        return _page(const LoginPage(), settings);
      case registerRoute:
        return _page(const RegisterPage(), settings);
      case forgotPasswordRoute:
        return _page(ForgotPasswordPage(email: settings.arguments as String?), settings);
      case resetPasswordRoute:
        return _page(ResetPasswordPage(email: settings.arguments as String? ?? ''), settings);
      case clientRoute:
        return _page(const ClientHomePage(), settings);
      case creationColisRoute:
        return _guarded(
          AssistantExpeditionPage(
            preremplissage: settings.arguments as PreremplissageExpedition? ?? const PreremplissageExpedition(),
          ),
          settings,
        );
      case detailColisRoute:
        return _guarded(DetailColisPage(colisId: settings.arguments as String? ?? ''), settings);
      case suiviColisRoute:
        return _guarded(SuiviColisPage(colisId: settings.arguments as String? ?? ''), settings);
      default:
        return _page(const LoginPage(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget w, RouteSettings s) =>
      MaterialPageRoute(builder: (_) => w, settings: s);

  static MaterialPageRoute<dynamic> _guarded(Widget w, RouteSettings s) =>
      MaterialPageRoute(builder: (_) => _AuthGuard(child: w), settings: s);
}

class _AuthGuard extends StatefulWidget {
  final Widget child;
  const _AuthGuard({required this.child});
  @override
  State<_AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<_AuthGuard> {
  late Future<bool> _check;

  @override
  void initState() {
    super.initState();
    _check = isUserAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == true) return widget.child;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(ctx).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
        });
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
