import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/i18n/langue.dart';
import 'package:yobante_colis/core/utils/formatters.dart';

/// Les séparateurs de milliers varient selon la locale (espace insécable) :
/// on compare les montants sans espaces.
String _compact(String s) => s.replaceAll(RegExp(r'[\s  ]'), '');

void main() {
  tearDown(() => LangueApp.instance.value = Langue.fr);

  group('formaterMontant', () {
    test('euro : deux décimales et symbole €', () {
      LangueApp.instance.value = Langue.fr;
      final m = formaterMontant(1234.5, 'EUR');
      expect(m, endsWith(' €'));
      expect(_compact(m), '1234,50€');
    });

    test('franc CFA : arrondi sans centimes', () {
      LangueApp.instance.value = Langue.fr;
      expect(_compact(formaterMontant(26238.4, 'XOF')), '26238FCFA');
      expect(_compact(formaterMontant(26238.6, null)), '26239FCFA');
    });

    test('montant null traité comme 0', () {
      expect(_compact(formaterMontant(null, 'EUR')), '0,00€');
      expect(_compact(formaterMontant(null, 'XOF')), '0FCFA');
    });

    test('en anglais, séparateur décimal point', () {
      LangueApp.instance.value = Langue.en;
      expect(_compact(formaterMontant(1234.5, 'EUR')), '1,234.50€');
    });
  });

  group('formaterDate', () {
    test('valeur absente ou vide : tiret', () {
      expect(formaterDate(null), '—');
      expect(formaterDate(''), '—');
    });

    test('valeur non interprétable renvoyée telle quelle', () {
      expect(formaterDate('bientôt'), 'bientôt');
    });
  });

  test('nettoyerTelephone retire espaces, tirets, points et parenthèses', () {
    expect(nettoyerTelephone(' (+33) 6.12-34 56 78 '), '+33612345678');
  });
}
