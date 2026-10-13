import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/features/devis/presentation/pages/devis_page.dart';

import '../../faux_backend.dart';

/// « Calculer un tarif » : erreurs visibles au bon endroit, et besoin envoyé au
/// serveur conforme à la saisie. Le prix vient toujours du serveur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();

  Map<String, dynamic> ville(String id, String nom, String pays) => {'id': id, 'nom': nom, 'pays': pays};

  setUp(() async {
    await env.preparer();
    env.backend.routes[Env.publicVilles] = (o) => ok({
      'villes': o.queryParameters['pays'] == 'FR'
          ? [ville('fr-paris', 'Paris', 'FR')]
          : [ville('sn-dakar', 'Dakar', 'SN')],
    });
    env.backend.routes[Env.publicTarifs] = (_) => ok({'articles': []});
    env.backend.routes[Env.publicDevis] = (_) => ok({
      'devis': {
        'offres': [
          {
            'service': {'id': 's1', 'nom': 'Maritime éco'},
            'devise': 'EUR',
            'montants': {'total': 48.5},
          },
        ],
      },
    });
  });

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DevisPage()));
    await tester.pumpAndSettle();
    // Polices chargées avant toute action (voir assistant_expedition_test.dart)
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();
  }

  Future<void> choisirVille(WidgetTester tester, String champ, String nom) async {
    await tester.tap(find.text(champ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(nom).last);
    await tester.pumpAndSettle();
  }

  Future<void> comparer(WidgetTester tester) async {
    await tester.tap(find.text('Comparer les offres'));
    await tester.pumpAndSettle();
  }

  testWidgets('villes non choisies : erreur sous chaque champ, aucun appel au serveur', (tester) async {
    await ouvrir(tester);
    await comparer(tester);

    expect(find.text('Choisissez la ville de départ.'), findsOneWidget);
    expect(find.text('Choisissez la ville de destination.'), findsOneWidget);
    expect(find.text('Tarif indisponible'), findsNothing);
    expect(env.backend.vers(Env.publicDevis), isEmpty);
  });

  testWidgets('une seule ville manquante : seul ce champ est signalé, puis l\'erreur disparaît', (tester) async {
    await ouvrir(tester);
    await choisirVille(tester, 'Ville de départ', 'Paris');
    await comparer(tester);

    expect(find.text('Choisissez la ville de départ.'), findsNothing);
    expect(find.text('Choisissez la ville de destination.'), findsOneWidget);

    await choisirVille(tester, 'Ville de destination', 'Dakar');
    expect(find.text('Choisissez la ville de destination.'), findsNothing);
  });

  testWidgets('type d\'envoi désélectionné : message sous les cartes, aucun appel au serveur', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('2. Colis moyen'));
    await tester.pumpAndSettle();
    expect(find.text('Poids (kg)'), findsNothing, reason: 'champs liés au type masqués');

    await comparer(tester);
    expect(find.text('Choisissez un type d\'envoi.'), findsOneWidget);
    expect(env.backend.vers(Env.publicDevis), isEmpty);

    await tester.tap(find.text('3. Colis XXL'));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez un type d\'envoi.'), findsNothing);
  });

  testWidgets('calcul complet : besoin transmis tel que saisi, offre du serveur affichée', (tester) async {
    await ouvrir(tester);
    await choisirVille(tester, 'Ville de départ', 'Paris');
    await choisirVille(tester, 'Ville de destination', 'Dakar');
    await tester.enterText(find.widgetWithText(TextFormField, 'Poids (kg)'), '12,5');
    await comparer(tester);

    final envoi = env.backend.vers(Env.publicDevis).single.data as Map<String, dynamic>;
    expect(envoi['categorie'], 'colis_moyen');
    expect(envoi['villeDepartId'], 'fr-paris');
    expect(envoi['villeArriveeId'], 'sn-dakar');
    expect((envoi['pieces'] as List).single['poidsKg'], 12.5, reason: 'virgule décimale acceptée');
    expect(
      envoi.keys.where((k) => k.contains('prix') || k.contains('montant') || k.contains('total')),
      isEmpty,
      reason: 'aucun prix calculé par l\'application',
    );
    expect(find.text('1 offre(s) disponible(s)'), findsOneWidget);
    expect(find.textContaining('Maritime éco'), findsOneWidget);
  });

  testWidgets('largeur plus grande que la longueur : refus avant tout appel', (tester) async {
    await ouvrir(tester);
    await choisirVille(tester, 'Ville de départ', 'Paris');
    await choisirVille(tester, 'Ville de destination', 'Dakar');
    await tester.enterText(find.widgetWithText(TextFormField, 'Poids (kg)'), '5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Longueur'), '20');
    await tester.enterText(find.widgetWithText(TextFormField, 'Largeur'), '40');
    await comparer(tester);

    expect(find.text('La largeur ne peut pas être supérieure à la longueur.'), findsOneWidget);
    expect(env.backend.vers(Env.publicDevis), isEmpty);
  });

  testWidgets('serveur en erreur : bandeau avec le message du serveur', (tester) async {
    env.backend.routes[Env.publicDevis] = (_) => (422, {'message': 'Trajet non desservi'});
    await ouvrir(tester);
    await choisirVille(tester, 'Ville de départ', 'Paris');
    await choisirVille(tester, 'Ville de destination', 'Dakar');
    await tester.enterText(find.widgetWithText(TextFormField, 'Poids (kg)'), '3');
    await comparer(tester);

    expect(find.text('Tarif indisponible'), findsOneWidget);
    expect(find.text('Trajet non desservi'), findsOneWidget);
  });
}
