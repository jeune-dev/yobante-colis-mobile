import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/i18n/langue.dart';
import 'package:yobante_colis/core/utils/formatters.dart';
import 'package:yobante_colis/core/utils/validateurs.dart';

/// Contrôles de saisie alignés sur le backend : un refus ici évite un 400.
void main() {
  setUp(() => LangueApp.instance.value = Langue.fr);

  group('normaliserTelephone', () {
    test('Sénégal : mobiles 7x et fixes 3x', () {
      expect(normaliserTelephone('77 123 45 67'), '+221771234567');
      expect(normaliserTelephone('33-823-45-67'), '+221338234567');
      expect(normaliserTelephone('221771234567'), '+221771234567');
    });

    test('France : 0X et 00 33', () {
      expect(normaliserTelephone('06 12 34 56 78'), '+33612345678');
      expect(normaliserTelephone('06.12.34.56.78'), '+33612345678');
      expect(normaliserTelephone('0033612345678'), '+33612345678');
      expect(normaliserTelephone('33612345678'), '+33612345678');
    });

    test('numéro déjà international conservé', () {
      expect(normaliserTelephone('+221 77 123 45 67'), '+221771234567');
    });

    test('9 chiffres sans indicatif : France seulement si demandé', () {
      expect(normaliserTelephone('612345678', paysParDefaut: 'FR'), '+33612345678');
      expect(normaliserTelephone('612345678'), '612345678');
    });
  });

  group('validerTelephone', () {
    test('accepte France et Sénégal', () {
      expect(validerTelephone('06 12 34 56 78'), isNull);
      expect(validerTelephone('77 123 45 67'), isNull);
      expect(validerTelephone('+221 33 823 45 67'), isNull);
    });

    test('refuse vide, autres pays et plages invalides', () {
      expect(validerTelephone(null), 'Numéro requis');
      expect(validerTelephone('  '), 'Numéro requis');
      expect(validerTelephone('+14155550100'), isNotNull);
      expect(validerTelephone('+221 57 123 45 67'), isNotNull); // ni 7x ni 3x
      expect(validerTelephone('+33 0 12 34 56 78'), isNotNull);
      expect(validerTelephone('123'), isNotNull);
    });
  });

  group('texte', () {
    test('requis, min et max', () {
      final v = texte(requis: true, min: 2, max: 5);
      expect(v(null), 'Champ requis');
      expect(v('  '), 'Champ requis');
      expect(v('a'), 'Au moins 2 caractères');
      expect(v('abcdef'), '5 caractères maximum');
      expect(v(' abc '), isNull);
    });

    test('facultatif vide accepté, message personnalisé', () {
      expect(texte()(''), isNull);
      expect(texte(requis: true, message: 'Nom ?')(''), 'Nom ?');
    });
  });

  group('email', () {
    test('formats', () {
      final v = email();
      expect(v(''), 'Email requis');
      expect(v('awa@yobante.sn'), isNull);
      expect(v('awa.diop+colis@mail.fr'), isNull);
      expect(v('awa@'), 'Email invalide');
      expect(v('awa@yobante'), 'Email invalide');
      expect(v('${'a' * 145}@x.com'), '150 caractères maximum');
      expect(email(requis: false)(''), isNull);
    });
  });

  group('telephone', () {
    test('facultatif ou requis', () {
      expect(telephone(requis: false)(''), isNull);
      expect(telephone()(''), 'Numéro requis');
      expect(telephone()('0612345678'), isNull);
    });
  });

  group('mot de passe', () {
    test('règle du backend', () {
      expect(RegleMotDePasse.valide('Colis2026!'), isTrue);
      expect(RegleMotDePasse.longueur('Ab1!'), isFalse);
      expect(RegleMotDePasse.majuscule('colis2026!'), isFalse);
      expect(RegleMotDePasse.chiffre('Colisssss!'), isFalse);
      expect(RegleMotDePasse.special('Colis2026'), isFalse);
      expect(RegleMotDePasse.longueur('A' * 73), isFalse);
    });

    test('messages', () {
      expect(motDePasse(null), 'Mot de passe requis');
      expect(motDePasse('A1!${'a' * 70}'), '72 caractères maximum');
      expect(motDePasse('faible'), contains('8 caractères minimum'));
      expect(motDePasse('Colis2026!'), isNull);
    });
  });

  group('codePostal', () {
    test('France : 5 chiffres', () {
      final v = codePostal(pays: 'FR');
      expect(v('75001'), isNull);
      expect(v('7500'), 'Code postal à 5 chiffres');
      expect(v('7500A'), 'Code postal à 5 chiffres');
      expect(v(''), isNull);
      expect(codePostal(pays: 'FR', requis: true)(''), 'Code postal requis');
    });

    test('ailleurs : 10 caractères au plus', () {
      expect(codePostal(pays: 'SN')('12000'), isNull);
      expect(codePostal(pays: 'SN')('12345678901'), '10 caractères maximum');
    });
  });

  test('codeSixChiffres', () {
    expect(codeSixChiffres('123456'), isNull);
    expect(codeSixChiffres(' 123456 '), isNull);
    expect(codeSixChiffres('12345'), 'Code à 6 chiffres');
    expect(codeSixChiffres('12a456'), 'Code à 6 chiffres');
    expect(codeSixChiffres(null), 'Code à 6 chiffres');
  });

  group('nombre', () {
    test('virgule acceptée, bornes', () {
      final v = nombre(requis: true, min: 1, max: 30);
      expect(v(''), 'Valeur requise');
      expect(v('abc'), 'Nombre invalide');
      expect(v('2,5'), isNull);
      expect(v('0.5'), 'Minimum 1.0');
      expect(v('31'), 'Maximum 30');
      expect(nombre(max: 2.5)('3'), 'Maximum 2.5');
    });

    test('strictement positif', () {
      final v = nombre(strictementPositif: true);
      expect(v('0'), 'Doit être supérieur à 0');
      expect(v('0,1'), isNull);
    });
  });

  test('entier', () {
    final v = entier(requis: true, min: 1, max: 10);
    expect(v(''), 'Valeur requise');
    expect(v('2.5'), 'Nombre entier attendu');
    expect(v('0'), 'Entre 1 et 10');
    expect(v('11'), 'Entre 1 et 10');
    expect(v('10'), isNull);
  });

  test('tous : le premier message d\'erreur l\'emporte', () {
    final v = tous([texte(requis: true), texte(min: 3), texte(max: 4)]);
    expect(v(''), 'Champ requis');
    expect(v('ab'), 'Au moins 3 caractères');
    expect(v('abcdef'), '4 caractères maximum');
    expect(v('abc'), isNull);
  });

  test('messages traduits en anglais', () {
    LangueApp.instance.value = Langue.en;
    addTearDown(() => LangueApp.instance.value = Langue.fr);
    expect(texte(requis: true)(''), isNot('Champ requis'));
  });
}
