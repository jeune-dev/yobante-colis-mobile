import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/widgets/adaptation_ecran.dart';

/// Rend [AdaptationEcran] sur un écran de [largeur] × 900, avec un facteur de
/// texte [texte], et renvoie la largeur et le facteur de texte vus par l'enfant.
Future<(double, double)> _mesurer(WidgetTester tester, double largeur, {double texte = 1}) async {
  late double largeurVue;
  late double texteVu;
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(size: Size(largeur, 900), textScaler: TextScaler.linear(texte)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: AdaptationEcran(
        child: Builder(builder: (context) {
          largeurVue = MediaQuery.sizeOf(context).width;
          texteVu = MediaQuery.textScalerOf(context).scale(1);
          return const SizedBox.expand();
        }),
      ),
    ),
  ));
  return (largeurVue, texteVu);
}

void main() {
  testWidgets('téléphone : toute la largeur', (tester) async {
    final (largeur, _) = await _mesurer(tester, 375);
    expect(largeur, 375);
  });

  testWidgets('tablette : contenu centré sur une colonne de largeur téléphone', (tester) async {
    final (largeur, _) = await _mesurer(tester, 1024);
    expect(largeur, AdaptationEcran.largeurMax);
    expect(tester.getSize(find.byType(SizedBox).last).width, AdaptationEcran.largeurMax);
  });

  testWidgets('taille du texte bornée entre 0,9 et 1,3', (tester) async {
    expect((await _mesurer(tester, 375, texte: 2.0)).$2, 1.3);
    expect((await _mesurer(tester, 375, texte: 0.5)).$2, 0.9);
    expect((await _mesurer(tester, 375, texte: 1.1)).$2, closeTo(1.1, 0.001));
  });
}
