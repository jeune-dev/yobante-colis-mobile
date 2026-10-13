import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/theme/app_theme.dart';
import 'package:yobante_colis/features/colis/presentation/pages/colis_liste_page.dart';
import 'package:yobante_colis/features/colis/presentation/pages/detail_colis_page.dart';
import 'package:yobante_colis/features/home/presentation/pages/envois_page.dart';

import '../../faux_backend.dart';

/// « Mes envois » : une reconstruction de l'écran parent (clavier, thème…) ne doit
/// ni recharger la liste ni perdre la saisie ; la feuille « Modifier ma demande »
/// se ferme sans erreur et libère ses champs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();

  String jwtValide() {
    String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    return '${b64({'alg': 'HS256'})}.${b64({'sub': 'u1', 'exp': 9999999999})}.signature';
  }

  setUp(() async {
    await env.preparer();
    Environnement.stockage.valeurs['jwt_token'] = jwtValide();
    env.backend.routes[Env.clientColis] = (_) => ok({
      'colis': [],
      'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
    });
  });

  testWidgets('reconstruction du parent : ni rechargement ni recherche perdue', (tester) async {
    late StateSetter reconstruire;
    var compteur = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            reconstruire = setState;
            return Column(
              children: [
                Text('reconstruction $compteur'),
                const Expanded(child: ColisListePage(integre: true)),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(env.backend.vers(Env.clientColis), hasLength(1));

    // Recherche lancée après la pause de frappe : 2e requête, attendue
    await tester.enterText(find.byType(TextField), 'PNCO');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(env.backend.vers(Env.clientColis), hasLength(2));
    expect(env.backend.vers(Env.clientColis).last.queryParameters['reference'], 'PNCO');

    for (var i = 0; i < 3; i++) {
      reconstruire(() => compteur++);
      await tester.pumpAndSettle();
    }

    expect(find.text('reconstruction 3'), findsOneWidget);
    expect(env.backend.vers(Env.clientColis), hasLength(2), reason: 'aucun rechargement à la reconstruction');
    expect(find.text('PNCO'), findsOneWidget, reason: 'la recherche saisie est conservée');
  });

  testWidgets('feuille « Modifier ma demande » : ouverte, fermée, champs libérés sans erreur', (tester) async {
    env.backend.routes[Env.clientColisId('c1')] = (_) => ok({
      'colis': {
        'id': 'c1',
        'reference': 'PNCO2610060001ADI01',
        'statut': 'en_attente_depot',
        'modifiable': true,
        'destinataireNom': 'Awa Séye',
        'destinataireTelephone': '+221771234567',
      },
    });
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Thème de l'application : ses polices donnent les vraies largeurs de texte
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const DetailColisPage(colisId: 'c1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier ma demande'), findsOneWidget);
    expect(find.text('771234567'), findsOneWidget, reason: 'téléphone affiché avec son drapeau');

    // Fermeture par glissement / toucher hors de la feuille, puis délai de libération des champs
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Modifier ma demande'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('changement d\'onglet « Envoyés » → « Reçus » : le clavier se ferme', () {
    setUp(() {
      env.backend.routes[Env.clientColisRecus] = (_) => ok({
        'colis': [],
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
      });
    });

    Future<void> ouvrirClavier(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const EnvoisPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
    }

    testWidgets('en touchant l\'onglet', (tester) async {
      await ouvrirClavier(tester);
      await tester.tap(find.text('Reçus'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('en glissant d\'un onglet à l\'autre', (tester) async {
      await ouvrirClavier(tester);
      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Aucun colis reçu').evaluate().isNotEmpty || find.byType(TextField).evaluate().isEmpty, isTrue);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('en touchant en dehors du champ de recherche', (tester) async {
      await ouvrirClavier(tester);
      await tester.tapAt(const Offset(400, 400));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });
}
