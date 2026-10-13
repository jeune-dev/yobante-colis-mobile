import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:toastification/toastification.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/features/expedition/presentation/pages/assistant_expedition_page.dart';

import '../../faux_backend.dart';

/// Appareil photo simulé : chaque prise renvoie la même image.
class _AppareilPhoto extends ImagePickerPlatform {
  final String chemin;
  _AppareilPhoto(this.chemin);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile(chemin);
}

/// Assistant d'expédition : contrôles de chaque étape avant de continuer, et
/// recherche du destinataire dans le carnet, faite par le serveur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();
  late Directory dossier;

  Map<String, dynamic> ville(String id, String nom, String pays) => {'id': id, 'nom': nom, 'pays': pays};

  setUpAll(() {
    dossier = Directory.systemTemp.createTempSync('assistant_test');
    final photo = File('${dossier.path}/colis.jpg')..writeAsBytesSync(List.filled(64, 0));
    ImagePickerPlatform.instance = _AppareilPhoto(photo.path);
  });
  tearDownAll(() => dossier.deleteSync(recursive: true));

  setUp(() async {
    await env.preparer();
    final b = env.backend.routes;
    b[Env.publicConfiguration] = (_) => ok({'configuration': <String, dynamic>{}});
    b[Env.publicVilles] = (o) => ok({
      'villes': o.queryParameters['pays'] == 'FR'
          ? [ville('fr-paris', 'Paris', 'FR')]
          : [ville('sn-dakar', 'Dakar', 'SN')],
    });
    b[Env.publicTarifs] = (_) => ok({'articles': []});
    b[Env.publicEmballages] = (_) => ok({'emballages': []});
    b[Env.publicPointsCollecte] = (_) => ok({'points': []});
    b[Env.publicTournees] = (_) => ok({'tournees': []});
  });

  Future<void> ouvrir(WidgetTester tester, [PreremplissageExpedition p = const PreremplissageExpedition()]) async {
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(home: AssistantExpeditionPage(preremplissage: p)),
      ),
    );
    await tester.pumpAndSettle();
    // Polices chargées avant toute action : en test, une police chargée entre la mise en
    // page et le dessin d'un texte déclenche une assertion de Flutter (sans effet dans l'app)
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();
  }

  /// « Continuer » puis attente de l'écran suivant ou de la notification d'erreur.
  Future<void> continuer(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Attend la notification (toast) portant [texte], affichée après quelques images.
  Future<Finder> notification(WidgetTester tester, String texte) async {
    final cible = find.text(texte);
    for (var i = 0; i < 20 && cible.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return cible;
  }

  Future<void> laisserFermerToasts(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('étape 1 : type d\'envoi décoché, l\'assistant ne continue pas', (tester) async {
    await ouvrir(tester, const PreremplissageExpedition(villeDepartId: 'fr-paris', villeArriveeId: 'sn-dakar'));
    await tester.tap(find.text('2. Colis moyen'));
    await tester.pumpAndSettle();
    await continuer(tester);

    expect(await notification(tester, 'Choisissez un type d\'envoi.'), findsOneWidget);
    expect(find.textContaining('Étape 1 sur 5'), findsOneWidget);
    await laisserFermerToasts(tester);
  });

  testWidgets('étape 1 : villes manquantes, l\'assistant ne continue pas', (tester) async {
    await ouvrir(tester);
    await continuer(tester);

    expect(await notification(tester, 'Choisissez la ville de départ et d\'arrivée.'), findsOneWidget);
    expect(find.textContaining('Étape 1 sur 5'), findsOneWidget);
    await laisserFermerToasts(tester);
  });

  testWidgets('étape 2 : valeur estimée exigée pour un colis moyen', (tester) async {
    await ouvrir(
      tester,
      const PreremplissageExpedition(villeDepartId: 'fr-paris', villeArriveeId: 'sn-dakar', poidsKg: 4),
    );
    await continuer(tester);
    expect(find.textContaining('Étape 2 sur 5'), findsOneWidget);

    await tester.tap(find.text('Neuf'));
    await tester.pump();
    await continuer(tester);
    expect(await notification(tester, 'Indiquez la valeur estimée du contenu.'), findsOneWidget);
    expect(find.textContaining('Étape 2 sur 5'), findsOneWidget);
    await laisserFermerToasts(tester);
  });

  testWidgets('étape 4 : destinataire recherché sur le serveur puis pré-rempli', (tester) async {
    // Faux carnet qui répond comme le serveur de production : sans texte, tout le carnet du
    // type demandé ; avec un texte, recherche sur le nom et le libellé, et le filtre de type
    // est perdu (un contact « expéditeur » peut revenir)
    final carnet = [
      {
        'id': 'a1',
        'libelle': 'Maman',
        'type': 'destinataire',
        'nom': 'Awa Séye',
        'telephone': '+221771234567',
        'email': 'awa@exemple.sn',
        'pays': 'SN',
        'villeId': 'sn-dakar',
        'adresse': '12 rue Carnot',
        'quartier': 'Plateau',
      },
      {
        'id': 'a2',
        'libelle': 'Bureau',
        'type': 'destinataire',
        'nom': 'Fatou Ndiaye',
        'telephone': '+221781112233',
        'pays': 'SN',
        'villeId': 'sn-dakar',
        'adresse': 'Route de Ouakam',
      },
      {
        'id': 'a4',
        'libelle': 'Bro',
        'type': 'destinataire',
        'nom': 'Bro Bordeaux',
        'telephone': '+33655812332',
        'pays': 'FR',
        'villeId': 'fr-bordeaux',
        'adresse': 'psg',
      },
      {
        'id': 'a3',
        'libelle': 'Moi',
        'type': 'expediteur',
        'nom': 'Awa Expéditrice',
        'telephone': '+221770000000',
        'pays': 'SN',
        'villeId': 'sn-dakar',
        'adresse': 'Mermoz',
      },
    ];
    env.backend.routes[Env.clientAdresses] = (o) {
      final q = (o.queryParameters['search'] as String? ?? '').toLowerCase();
      return ok({
        'adresses': carnet
            .where(
              (a) => q.isEmpty
                  ? a['type'] != 'expediteur'
                  : (a['nom'] as String).toLowerCase().contains(q) ||
                        (a['libelle'] as String).toLowerCase().contains(q),
            )
            .toList(),
      });
    };
    await ouvrir(
      tester,
      const PreremplissageExpedition(villeDepartId: 'fr-paris', villeArriveeId: 'sn-dakar', poidsKg: 4),
    );
    await continuer(tester);

    // Étape 2 : contenu
    await tester.enterText(find.widgetWithText(TextFormField, 'Valeur estimée'), '300');
    await tester.tap(find.text('Neuf'));
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.textContaining('($i/3)'));
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider la photo'));
      await tester.pumpAndSettle();
    }
    await continuer(tester);
    expect(find.textContaining('Étape 3 sur 5'), findsOneWidget);

    // Étape 3 : remise du colis
    await tester.tap(find.text('Envoi par la poste'));
    await tester.pumpAndSettle();
    await continuer(tester);
    expect(find.textContaining('Étape 4 sur 5'), findsOneWidget);

    // Étape 4 sans destinataire, sur un écran de téléphone réel : la page défile jusqu'au champ manquant
    tester.view.physicalSize = const Size(390, 844) * 3;
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet').first, 'Moussa Diop');
    await tester.enterText(find.widgetWithText(TextFormField, 'Téléphone').first, '612345678');
    await tester.dragUntilVisible(
      find.text('Instructions de livraison (facultatif)'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    final avant = tester.getRect(find.widgetWithText(TextFormField, 'Nom complet').last).top;
    await continuer(tester);
    expect(await notification(tester, 'Nom du destinataire requis.'), findsOneWidget);
    // Défilement animé (300 ms) jusqu'au champ
    await tester.pump(const Duration(milliseconds: 400));
    final apres = tester.getRect(find.widgetWithText(TextFormField, 'Nom complet').last);
    expect(apres.top, isNot(avant), reason: 'la page a défilé');
    expect(apres.top, greaterThanOrEqualTo(0));
    expect(apres.bottom, lessThan(844), reason: 'champ du destinataire visible');
    await laisserFermerToasts(tester);

    // Étape 4 : rien n'est chargé à l'avance ; toucher le champ affiche tout le carnet
    expect(env.backend.vers(Env.clientAdresses), isEmpty);
    final recherche = find.widgetWithText(TextFormField, 'Rechercher dans mon carnet');
    await tester.ensureVisible(recherche);
    await tester.tap(recherche);
    await tester.pumpAndSettle();
    expect(env.backend.vers(Env.clientAdresses).last.queryParameters, {'type': 'destinataire', 'limit': 50});
    expect(find.text('Awa Séye'), findsOneWidget);
    expect(find.text('Fatou Ndiaye'), findsOneWidget, reason: 'tout le carnet affiché avant de taper');
    // Contact en France pour un envoi vers le Sénégal : listé en dernier, grisé et expliqué
    expect(find.text('Bro Bordeaux'), findsOneWidget);
    expect(find.text('Adresse en France : hors de ce trajet'), findsOneWidget);
    expect(tester.getRect(find.text('Bro Bordeaux')).top, greaterThan(tester.getRect(find.text('Fatou Ndiaye')).top));
    await tester.tap(find.text('Bro Bordeaux'));
    await tester.pump();
    expect(await notification(tester, 'Adresse hors trajet'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Bro Bordeaux'), findsNothing, reason: 'formulaire non rempli');
    await laisserFermerToasts(tester);

    // Chaque lettre affine la liste
    await tester.enterText(recherche, 'aw');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Awa Séye'), findsOneWidget);
    expect(find.text('Fatou Ndiaye'), findsNothing);

    // Contact « expéditeur » renvoyé par le serveur pendant la recherche : écarté par l'application
    expect(find.text('Awa Expéditrice'), findsNothing);

    // Recherche par libellé
    await tester.enterText(recherche, 'bureau');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Fatou Ndiaye'), findsOneWidget);
    expect(find.text('Awa Séye'), findsNothing);

    // Clavier iOS : mises à jour supplémentaires sans changement de texte (mot en cours de
    // saisie, puis validé), qui ne doivent pas effacer les suggestions
    await tester.enterText(recherche, 'awa');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'awa',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: 'awa', selection: TextSelection.collapsed(offset: 3)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Awa Séye'), findsOneWidget, reason: 'suggestion affichée malgré les mises à jour du clavier');
    expect(
      env.backend.vers(Env.clientAdresses).where((r) => r.queryParameters['search'] == 'awa'),
      hasLength(1),
      reason: 'une seule requête pour un même texte',
    );

    // Toucher réel : doigt posé, image suivante, doigt levé (un clic instantané masquait
    // la fermeture de la liste au moment où le doigt se pose)
    final doigt = await tester.startGesture(tester.getCenter(find.text('Awa Séye').last));
    await tester.pump(const Duration(milliseconds: 80));
    await doigt.up();
    await tester.pumpAndSettle();
    // Le nom choisi s'affiche dans la recherche et dans le champ « Nom complet » du destinataire
    expect(find.widgetWithText(TextFormField, 'Awa Séye'), findsNWidgets(2));
    expect(find.text('771234567'), findsOneWidget, reason: 'numéro national affiché avec le drapeau +221');
    expect(find.text('12 rue Carnot'), findsOneWidget);
    expect(find.text('Plateau'), findsOneWidget);
  });
}
