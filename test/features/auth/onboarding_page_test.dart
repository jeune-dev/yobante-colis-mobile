import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante_colis/features/auth/presentation/pages/onboarding_page.dart';

/// Écran d'accueil : un nouvel utilisateur doit voir les trois actions (créer un
/// compte, se connecter, continuer sans compte) sans avoir à faire défiler,
/// y compris sur un petit téléphone et avec le texte agrandi (plafonné à 1,3).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const ecrans = {
    'petit Android (360 × 640)': Size(360, 640),
    'iPhone SE (375 × 667)': Size(375, 667),
    'iPhone 15 Pro (393 × 852)': Size(393, 852),
  };

  for (final MapEntry(key: nom, value: taille) in ecrans.entries) {
    for (final texte in [1.0, 1.3]) {
      testWidgets('$nom, texte × $texte : les trois actions sont visibles', (tester) async {
        tester.view.physicalSize = taille * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = texte;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
        await tester.pump();

        for (final libelle in ['Créer un compte', 'Se connecter', 'Continuer sans compte']) {
          final zone = tester.getRect(find.text(libelle));
          expect(zone.top, greaterThanOrEqualTo(0), reason: '« $libelle » sort par le haut');
          expect(zone.bottom, lessThanOrEqualTo(taille.height), reason: '« $libelle » est sous le bord de l\'écran');
        }
        expect(tester.takeException(), isNull, reason: 'débordement de mise en page');
      });
    }
  }
}
