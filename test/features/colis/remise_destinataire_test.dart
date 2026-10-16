import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastification/toastification.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/theme/app_theme.dart';
import 'package:yobante_colis/features/colis/presentation/pages/recus_colis_page.dart';
import 'package:yobante_colis/features/personnel/presentation/pages/colis_terrain_page.dart';

import '../../faux_backend.dart';

/// Remise confirmée dans l'application du destinataire : l'agent affiche un code
/// à usage unique, le destinataire le saisit, puis son avis lui est proposé.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();

  String jwtValide() {
    String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    return '${b64({'alg': 'HS256'})}.${b64({'sub': 'u1', 'exp': 9999999999})}.signature';
  }

  Map<String, dynamic> colis(String statut) => {
    'id': 'c1',
    'reference': 'PNCO0313102026AGU03',
    'statut': statut,
    'categorie': 'colis',
    'expediteurNom': 'Moussa Fall',
    'destinataireNom': 'Awa Diop',
    'destinataireTelephone': '+221771234567',
    'createdAt': '2026-10-13T08:00:00Z',
  };

  setUp(() async {
    await env.preparer();
    await initializeDateFormatting('fr_FR');
    Environnement.stockage.valeurs['jwt_token'] = jwtValide();
  });

  /// L'écran terrain anime en continu : on avance le temps au lieu d'attendre le repos.
  Future<void> avancer(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> afficher(WidgetTester tester, Widget page, {bool repos = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(theme: AppTheme.light(), home: page),
      ),
    );
    if (!repos) return avancer(tester);
    await tester.pumpAndSettle();
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();
  }

  group('destinataire', () {
    var statut = 'disponible_retrait';
    setUp(() {
      statut = 'disponible_retrait';
      env.backend.routes[Env.clientColisRecus] = (_) => ok({
        'colis': [colis(statut)],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      });
    });

    testWidgets('saisit le code de l\'agent : réception confirmée, puis avis proposé', (tester) async {
      env.backend.routes[Env.clientColisConfirmerRemise('c1')] = (o) {
        statut = 'recupere';
        return (200, {'success': true, 'message': 'Réception confirmée.', 'data': {}});
      };
      await afficher(tester, const RecusColisPage());

      expect(find.text('Donner mon avis'), findsNothing);
      await tester.tap(find.text('Confirmer la réception'));
      await tester.pumpAndSettle();
      // Le sixième chiffre suffit : pas de bouton à toucher
      await tester.enterText(find.byType(TextField), '482913');
      await tester.pumpAndSettle();

      final envoi = env.backend.vers(Env.clientColisConfirmerRemise('c1')).single;
      expect((envoi.data as Map)['code'], '482913');
      // L'avis s'ouvre aussitôt sur ce colis
      expect(find.text('Votre avis'), findsOneWidget);
      expect(find.text('Expédition PNCO0313102026AGU03'), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Donner mon avis'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('code refusé : message du serveur, champ vidé, la feuille reste ouverte', (tester) async {
      env.backend.routes[Env.clientColisConfirmerRemise('c1')] = (_) =>
          (400, {'success': false, 'message': 'Code incorrect'});
      await afficher(tester, const RecusColisPage());
      await tester.tap(find.text('Confirmer la réception'));
      await tester.pumpAndSettle();
      expect(find.text('Envoyé par Moussa Fall'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();
      expect(find.text('Code incorrect'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(find.text('Votre avis'), findsNothing);
      // Code incomplet validé au bouton : rien n'est envoyé
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('J\'ai reçu mon colis'));
      await tester.pumpAndSettle();
      expect(find.text('Le code compte six chiffres.'), findsOneWidget);
      expect(env.backend.vers(Env.clientColisConfirmerRemise('c1')), hasLength(1));
    });

    testWidgets('avis déjà donné : plus de bouton « Donner mon avis »', (tester) async {
      env.backend.routes[Env.clientColisRecus] = (_) => ok({
        'colis': [
          {...colis('livre'), 'avisDonne': true},
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      });
      await afficher(tester, const RecusColisPage());
      expect(find.text('Donner mon avis'), findsNothing);
    });

    testWidgets('en livraison : confirmation proposée sans insister', (tester) async {
      statut = 'en_livraison';
      await afficher(tester, const RecusColisPage());
      expect(find.widgetWithText(OutlinedButton, 'Confirmer la réception'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirmer la réception'), findsNothing);
    });

    testWidgets('colis déjà reçu : avis directement depuis la liste', (tester) async {
      statut = 'livre';
      await afficher(tester, const RecusColisPage());
      expect(find.text('Confirmer la réception'), findsNothing);
      await tester.tap(find.text('Donner mon avis'));
      await tester.pumpAndSettle();
      expect(find.text('Votre avis'), findsOneWidget);
    });
  });

  group('agent', () {
    var statut = 'disponible_retrait';
    var aCompte = true;
    Map<String, dynamic>? facture;
    bool? reglementExige;
    setUp(() {
      statut = 'disponible_retrait';
      aCompte = true;
      facture = null;
      reglementExige = null;
      env.backend.routes[Env.personnelColisId('c1')] = (_) => ok({
        'colis': {
          ...colis(statut),
          'modeLivraison': 'point_retrait',
          'aCodeRetrait': true,
          'destinataireACompte': aCompte,
          'facture': ?facture,
          'reglementAvantRemise': ?reglementExige,
          'evenementsPossibles': [
            if (statut == 'disponible_retrait')
              {'code': 'RETIRE', 'libelle': 'Retiré par le destinataire', 'statutInduit': 'recupere'},
            {'code': 'INFO', 'libelle': 'Information', 'statutInduit': null},
          ],
        },
      });
      env.backend.routes[Env.personnelColisCodeRemise('c1')] = (_) => ok({
        'code': '482913',
        'codeEvenement': 'RETIRE',
        'expireLe': DateTime.now().add(const Duration(minutes: 10)).toUtc().toIso8601String(),
      });
    });

    testWidgets('affiche le code, puis se ferme quand le destinataire a confirmé', (tester) async {
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('482 913'), findsOneWidget);
      expect(find.text('En attente de la confirmation du destinataire…'), findsOneWidget);

      // Le destinataire confirme sur son appareil : le prochain contrôle le voit
      statut = 'recupere';
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsNothing);
      expect(find.text('Le destinataire a confirmé la réception.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('choisir « Retiré » dans le suivi passe aussi par le code', (tester) async {
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Suivi'));
      await avancer(tester);
      await tester.tap(find.text('Retiré par le destinataire'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsOneWidget);
      expect(env.backend.vers(Env.personnelColisEvenement('c1')), isEmpty);
      await tester.tap(find.text('Fermer'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('autre changement de statut : la feuille se ferme sans annoncer de remise', (tester) async {
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      statut = 'incident';
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsNothing);
      expect(find.text('Le destinataire a confirmé la réception.'), findsNothing);
    });

    testWidgets('code expiré : un nouveau code s\'affiche tout seul', (tester) async {
      var appels = 0;
      env.backend.routes[Env.personnelColisCodeRemise('c1')] = (_) {
        appels++;
        return ok({
          'code': appels == 1 ? '482913' : '650127',
          'expireLe': DateTime.now()
              .add(appels == 1 ? const Duration(seconds: 2) : const Duration(minutes: 10))
              .toUtc()
              .toIso8601String(),
        });
      };
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('650 127'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('sans l\'application : saisie classique, tracée dans le commentaire', (tester) async {
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Sans l\'application'));
      await avancer(tester);
      expect(find.text('Code de retrait'), findsOneWidget);
      expect(find.text('Remis sans confirmation dans l\'application.'), findsOneWidget);
    });

    testWidgets('colis sorti des missions pendant l\'attente : la feuille se ferme', (tester) async {
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      env.backend.routes[Env.personnelColisId('c1')] = (_) => (404, {'success': false, 'message': 'Introuvable'});
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsNothing);
      expect(find.text('Le destinataire a confirmé la réception.'), findsNothing);
    });

    testWidgets('destinataire sans compte : « Remettre le colis » ouvre la saisie classique', (tester) async {
      aCompte = false;
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await avancer(tester);
      expect(find.text('Code de retrait'), findsOneWidget);
      expect(env.backend.vers(Env.personnelColisCodeRemise('c1')), isEmpty);
    });

    testWidgets('reste à payer : rappel avant la remise', (tester) async {
      facture = {
        'id': 'f1',
        'reference': 'FAC-1',
        'devise': 'XOF',
        'montantTotal': 5000,
        'montantPaye': 0,
        'statut': 'en_attente',
      };
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await avancer(tester);
      expect(find.text('Reste à payer'), findsWidgets);
      await tester.tap(find.text('Remettre quand même'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('reste à payer encaissé : la remise reprend d\'elle-même', (tester) async {
      facture = {
        'id': 'f1',
        'reference': 'FAC-1',
        'devise': 'XOF',
        'montantTotal': 5000,
        'montantPaye': 0,
        'statut': 'en_attente',
      };
      env.backend.routes[Env.personnelEncaissement('f1')] = (_) {
        facture = {...facture!, 'montantPaye': 5000, 'statut': 'payee'};
        return ok({});
      };
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await avancer(tester);
      await tester.tap(find.text('Encaisser').last);
      await avancer(tester);
      await tester.tap(find.text('Enregistrer'));
      await avancer(tester);
      expect(find.text('482 913'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pump(const Duration(milliseconds: 500));
      // Laisse la notification « Paiement enregistré » se refermer
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('règlement exigé par le serveur : pas de « Remettre quand même »', (tester) async {
      reglementExige = true;
      facture = {
        'id': 'f1',
        'reference': 'FAC-1',
        'devise': 'XOF',
        'montantTotal': 5000,
        'montantPaye': 0,
        'statut': 'en_attente',
      };
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await avancer(tester);
      expect(find.text('Remettre quand même'), findsNothing);
      await tester.tap(find.text('Annuler'));
      await avancer(tester);
      expect(env.backend.vers(Env.personnelColisCodeRemise('c1')), isEmpty);
    });

    testWidgets('paiement différé : aucun rappel, le code s\'affiche', (tester) async {
      reglementExige = false;
      facture = {
        'id': 'f1',
        'reference': 'FAC-1',
        'devise': 'XOF',
        'montantTotal': 5000,
        'montantPaye': 0,
        'statut': 'en_attente',
      };
      await afficher(tester, const DetailColisTerrainPage(id: 'c1'), repos: false);
      await tester.tap(find.text('Remettre le colis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('482 913'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
