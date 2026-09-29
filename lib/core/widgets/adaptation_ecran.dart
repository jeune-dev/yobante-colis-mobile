import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_color.dart';

/// Adaptation de l'application aux différents appareils, appliquée à tous les
/// écrans (via `MaterialApp.builder`) :
///
/// - taille du texte : le réglage d'accessibilité du téléphone est respecté,
///   mais borné pour que les mises en page ne débordent pas ;
/// - tablettes : le contenu est centré dans une colonne de largeur « téléphone »
///   au lieu d'être étiré sur tout l'écran (formulaires, cartes et listes restent
///   lisibles, feuilles et boîtes de dialogue comprises).
class AdaptationEcran extends StatelessWidget {
  final Widget child;
  const AdaptationEcran({super.key, required this.child});

  /// Largeur à partir de laquelle l'appareil est traité comme une tablette.
  static const double seuilTablette = 600;

  /// Largeur maximale du contenu sur tablette.
  static const double largeurMax = 560;

  static const double _texteMin = 0.9;
  static const double _texteMax = 1.3;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final texte = mq.textScaler.clamp(minScaleFactor: _texteMin, maxScaleFactor: _texteMax);
    final largeur = mq.size.width;

    if (largeur <= largeurMax + 40) {
      return MediaQuery(data: mq.copyWith(textScaler: texte), child: child);
    }

    // Tablette (ou grand écran) : colonne centrée, fond de l'application autour
    final marge = (largeur - largeurMax) / 2;
    return ColoredBox(
      color: AppColor.kBackground,
      child: Center(
        child: SizedBox(
          width: largeurMax,
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: texte,
              size: Size(largeurMax, mq.size.height),
              // Les marges latérales ne concernent plus la colonne centrée
              padding: mq.padding.copyWith(left: 0, right: 0),
              viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              viewInsets: mq.viewInsets.copyWith(left: (mq.viewInsets.left - marge).clamp(0, double.infinity),
                  right: (mq.viewInsets.right - marge).clamp(0, double.infinity)),
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }

  /// Portrait sur téléphone ; toutes les orientations sur tablette (le contenu
  /// y reste centré). À appeler avant `runApp`.
  static Future<void> configurerOrientation() {
    final vue = PlatformDispatcher.instance.views.first;
    final plusPetitCote = vue.physicalSize.shortestSide / vue.devicePixelRatio;
    return SystemChrome.setPreferredOrientations(
      plusPetitCote >= seuilTablette
          ? DeviceOrientation.values
          : const [DeviceOrientation.portraitUp],
    );
  }
}
