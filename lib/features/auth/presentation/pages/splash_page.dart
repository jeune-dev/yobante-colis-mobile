import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../../../core/demo/demo_config.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/version_service.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';

const String kHasSeenOnboardingKey = 'has_seen_onboarding';

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

    // Version minimale imposée par le backend : bloque ici si une mise à jour est obligatoire
    if (!kDemoMode) await VersionService.verifier(context);
    if (!mounted) return;
    // Règles des catégories et configuration publique, chargées en arrière-plan
    if (!kDemoMode) {
      final catalogue = sl<CatalogueRemoteDataSource>();
      catalogue.chargerCategories().catchError((_) {});
      catalogue.getConfiguration().then((_) {}, onError: (_) {});
    }

    if (kDemoMode) {
      Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
      return;
    }

    try {
      final tokenService = sl<TokenService>();
      final isAuth = await tokenService.isAuthenticated;
      if (!mounted) return;

      if (isAuth) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
        return;
      }

      // Utilisateur non connecté : onboarding une seule fois, puis accès
      // direct à l'app en mode invité (les actions personnelles demandent
      // alors une connexion).
      final hasSeenOnboarding = sl<SharedPreferences>().getBool(kHasSeenOnboardingKey) ?? false;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(hasSeenOnboarding ? AppRouter.clientRoute : AppRouter.onboardingRoute);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fond blanc, comme l'écran de lancement natif (iOS / Android) : aucune
    // coupure de couleur entre les deux. Pictogramme à fond transparent.
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_yobante_icon.png', width: 112),
            const SizedBox(height: 24),
            Text(
              'Yobante Colis',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColor.kPrimary),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(minHeight: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
