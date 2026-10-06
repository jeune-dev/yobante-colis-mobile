import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/compteur_notifications.dart';
import '../theme/app_color.dart';

/// Pastille du nombre de notifications non lues, posée sur [child] (icône).
/// Se met à jour toute seule avec [CompteurNotifications] ; invisible à zéro.
class PastilleNotifications extends StatelessWidget {
  final Widget child;
  const PastilleNotifications({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CompteurNotifications.instance,
      builder: (_, total, _) => Badge(
        isLabelVisible: total > 0,
        backgroundColor: AppColor.kErreur,
        textColor: AppColor.kWhite,
        label: Text(total > 99 ? '99+' : '$total'),
        child: child,
      ),
    );
  }
}

/// Compteur en pastille arrondie, à placer en fin de ligne (menu, liste).
class CompteurNotificationsLigne extends StatelessWidget {
  const CompteurNotificationsLigne({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CompteurNotifications.instance,
      builder: (_, total, _) => total <= 0
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColor.kErreur, borderRadius: BorderRadius.circular(12)),
              child: Text(
                total > 99 ? '99+' : '$total',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kWhite),
              ),
            ),
    );
  }
}
