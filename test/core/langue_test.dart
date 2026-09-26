import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/core/i18n/langue.dart';
import 'package:yobnate_colis/core/i18n/traductions_en.dart';

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
}
