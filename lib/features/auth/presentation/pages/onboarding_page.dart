import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../injection_container.dart';
import 'splash_page.dart' show kHasSeenOnboardingKey;
import '../../../../core/i18n/langue.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static void _markSeen() {
    sl<SharedPreferences>().setBool(kHasSeenOnboardingKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Image.asset('assets/images/logo_yobante_icon.png', width: 160),
              const SizedBox(height: 40),
              Text(
                tr('Yobante Colis'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('Envoyez et suivez vos colis\npartout au Sénégal, simplement.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppColor.kGrayscale40,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 3),
              // Features rapides
              _FeatureRow(
                icon: Icons.track_changes_rounded,
                text: tr('Suivi en temps réel de vos envois'),
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon: Icons.receipt_long_rounded,
                text: tr('Factures et paiements en un clic'),
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon: Icons.notifications_active_rounded,
                text: tr('Notifications à chaque étape'),
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                text: tr('Créer un compte'),
                onTap: () {
                  _markSeen();
                  Navigator.of(context).pushNamed(AppRouter.registerRoute);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: tr('Se connecter'),
                onTap: () {
                  _markSeen();
                  Navigator.of(context).pushNamed(AppRouter.loginRoute);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _markSeen();
                  Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
                },
                child: Text(
                  tr('Continuer sans compte'),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColor.kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColor.kPrimary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
        ),
      ],
    );
  }
}

