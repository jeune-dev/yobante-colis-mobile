import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yobante_colis/core/i18n/langue.dart';
import 'package:yobante_colis/core/i18n/traductions_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => LangueApp.instance.value = Langue.fr);

  test('en français, les textes sont renvoyés tels quels', () {
    LangueApp.instance.value = Langue.fr;
    expect(tr('Mes factures'), 'Mes factures');
    expect(tr('Colis PNCO01'), 'Colis PNCO01');
  });

  test('en anglais, traduction exacte', () {
    LangueApp.instance.value = Langue.en;
    expect(tr('Mes factures'), 'My invoices');
    expect(tr('Carnet d\'adresses'), 'Address book');
  });

  test('en anglais, traduction des textes à variables', () {
    LangueApp.instance.value = Langue.en;
    expect(tr('Colis PNCO01'), 'Parcel PNCO01');
    expect(tr('Étape 3 sur 5 · Coordonnées'), 'Step 3 of 5 · Contact details');
    expect(tr('Facture FAC-12 — 40,00 €'), 'Invoice FAC-12 — 40,00 €');
  });

  test('un texte inconnu reste en français', () {
    LangueApp.instance.value = Langue.en;
    expect(tr('Texte absent du dictionnaire'), 'Texte absent du dictionnaire');
  });

  test('chaque traduction garde le même nombre de variables', () {
    for (final e in traductionsEn.entries) {
      expect('{}'.allMatches(e.value).length, '{}'.allMatches(e.key).length, reason: e.key);
    }
  });

  group('choix de la langue par l\'utilisateur', () {
    late List<Langue> enregistrees;
    var connecte = false;

    /// Simule un (re)démarrage de l'application avec les préférences du téléphone.
    Future<SharedPreferences> demarrer(Map<String, Object> preferences) async {
      SharedPreferences.setMockInitialValues(preferences);
      final prefs = await SharedPreferences.getInstance();
      LangueApp.instance.initialiser(prefs);
      enregistrees = [];
      LangueApp.instance.enregistrerDansProfil = (langue) async {
        if (!connecte) return false;
        enregistrees.add(langue);
        return true;
      };
      return prefs;
    }

    tearDown(() => connecte = false);

    test('anglais choisi : il reste après redémarrage, déconnexion et reconnexion', () async {
      connecte = true;
      final prefs = await demarrer({'langue_app': 'fr'});
      await LangueApp.instance.changer(Langue.en);
      expect(enregistrees, [Langue.en]);

      connecte = false; // déconnexion
      await demarrer(prefs.getKeys().fold<Map<String, Object>>({}, (m, k) => m..[k] = prefs.get(k)!));
      expect(LangueApp.instance.value, Langue.en);

      connecte = true; // reconnexion : le compte confirme l'anglais
      await LangueApp.instance.apresConnexion('en');
      expect(LangueApp.instance.value, Langue.en);
      expect(tr('Mes factures'), 'My invoices');
    });

    test('nouveau téléphone : la langue du compte s\'applique à la connexion', () async {
      await demarrer({});
      LangueApp.instance.value = Langue.fr;
      connecte = true;
      await LangueApp.instance.apresConnexion('en');
      expect(LangueApp.instance.value, Langue.en);
      expect(enregistrees, isEmpty);
    });

    test('choix fait avant de se connecter : il prime et part sur le compte', () async {
      await demarrer({'langue_app': 'fr'});
      await LangueApp.instance.changer(Langue.en); // hors connexion
      expect(enregistrees, isEmpty);

      connecte = true;
      await LangueApp.instance.apresConnexion('fr'); // le compte était en français
      expect(LangueApp.instance.value, Langue.en);
      expect(enregistrees, [Langue.en]);

      // Connexion suivante : le compte renvoie désormais l'anglais, plus rien à reporter
      await LangueApp.instance.apresConnexion('en');
      expect(LangueApp.instance.value, Langue.en);
      expect(enregistrees, [Langue.en]);
    });

    test('français choisi : rien ne change', () async {
      connecte = true;
      await demarrer({'langue_app': 'fr'});
      await LangueApp.instance.apresConnexion('fr');
      expect(LangueApp.instance.value, Langue.fr);
      expect(tr('Mes factures'), 'Mes factures');
      expect(enregistrees, isEmpty);
    });
  });
}
