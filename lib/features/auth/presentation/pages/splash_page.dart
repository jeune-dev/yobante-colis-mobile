import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../injection_container.dart';
import '../../../../core/config/user_role.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final tokenService = sl<TokenService>();
      final storage = sl<FlutterSecureStorage>();

      final isAuth = await tokenService.isAuthenticated;
      if (!mounted) return;

      if (isAuth) {
        final role = await storage.read(key: 'user_role');
        if (!mounted) return;

        final userRole = UserRoleX.fromString(role);
        if (userRole.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRouter.adminRoute);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
        }
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
