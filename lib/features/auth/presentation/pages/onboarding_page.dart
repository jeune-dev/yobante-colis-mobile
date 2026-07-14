import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

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
              // Illustration
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColor.kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColor.kPrimary,
                  size: 90,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Yobante Colis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Envoyez et suivez vos colis\npartout au SÃ©nÃ©gal, simplement.',
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
                text: 'Suivi en temps rÃ©el de vos envois',
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon: Icons.receipt_long_rounded,
                text: 'Factures et paiements en un clic',
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon: Icons.notifications_active_rounded,
                text: 'Notifications Ã  chaque Ã©tape',
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                text: 'CrÃ©er un compte',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRouter.registerRoute),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Se connecter',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.loginRoute),
              ),
              const SizedBox(height: 32),
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

