import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante_colis/core/widgets/avatar_utilisateur.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('initiales', () {
    test('prénom et nom → deux lettres en majuscules', () {
      expect(AvatarUtilisateur.initiales('Ali', 'Sow'), 'AS');
      expect(AvatarUtilisateur.initiales('awa', 'diop'), 'AD');
    });

    test('accents et espaces conservés correctement', () {
      expect(AvatarUtilisateur.initiales('  Élodie ', 'Ndiaye'), 'ÉN');
    });

    test('un seul des deux renseigné → une lettre', () {
      expect(AvatarUtilisateur.initiales('Moussa', null), 'M');
      expect(AvatarUtilisateur.initiales('', 'Fall'), 'F');
    });

    test('aucun nom → vide', () {
      expect(AvatarUtilisateur.initiales(null, ' '), '');
    });
  });

  testWidgets('sans photo : affiche les initiales', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AvatarUtilisateur(prenom: 'Ali', nom: 'Sow')),
    ));
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('sans nom ni photo : icône de personne', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AvatarUtilisateur())));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
