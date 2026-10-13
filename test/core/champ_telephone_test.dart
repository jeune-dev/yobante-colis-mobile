import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante_colis/core/widgets/champ_telephone.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> monter(WidgetTester tester, TextEditingController ctrl, {String pays = 'SN'}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChampTelephone(controller: ctrl, label: 'Téléphone', paysInitial: pays),
      ),
    ),
  );

  String saisi(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('numéro sénégalais saisi → contrôleur avec +221', (tester) async {
    final ctrl = TextEditingController();
    await monter(tester, ctrl);
    expect(find.text('+221'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '77 307 16 39');
    expect(ctrl.text, '+221773071639');
  });

  testWidgets('France : le 0 national est retiré', (tester) async {
    final ctrl = TextEditingController();
    await monter(tester, ctrl, pays: 'FR');
    expect(find.text('+33'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0612345678');
    expect(ctrl.text, '+33612345678');
  });

  testWidgets('numéro existant décomposé en drapeau + numéro national', (tester) async {
    final ctrl = TextEditingController(text: '+33612345678');
    await monter(tester, ctrl);
    expect(find.text('+33'), findsOneWidget);
    expect(saisi(tester), '612345678');
    expect(ctrl.text, '+33612345678');
  });

  testWidgets('remplissage extérieur (carnet d\'adresses) pris en compte', (tester) async {
    final ctrl = TextEditingController();
    await monter(tester, ctrl, pays: 'FR');
    ctrl.text = '+221771234567';
    await tester.pump();
    expect(find.text('+221'), findsOneWidget);
    expect(saisi(tester), '771234567');
  });

  testWidgets('champ vidé → contrôleur vide', (tester) async {
    final ctrl = TextEditingController(text: '+221771234567');
    await monter(tester, ctrl);
    await tester.enterText(find.byType(TextField), '');
    expect(ctrl.text, '');
  });
}
