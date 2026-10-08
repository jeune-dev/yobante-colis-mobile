import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/utils/formatters.dart';
import 'package:yobante_colis/core/utils/normalisation_nom.dart';
import 'package:yobante_colis/core/utils/validateurs.dart';

/// Contrôles de saisie de l'inscription, repris de SIGNS : messages précis.
void main() {
  group('validerTelephone : le refus nomme le problème', () {
    test('nombre de chiffres', () {
      expect(validerTelephone('+221 77 123 45'), contains('9 chiffres'));
      expect(validerTelephone('77 123 45'), contains('7 saisis'));
    });

    test('indicatif non desservi', () {
      expect(validerTelephone('+1 415 555 0100'), contains('Indicatif non pris en charge'));
    });

    test('plage non attribuée', () {
      expect(validerTelephone('+221 57 123 45 67'), contains('aucune plage'));
    });

    test('caractères interdits', () {
      expect(validerTelephone('77 12a 45 67'), contains('que des chiffres'));
    });

    test('sans indicatif, rattaché au pays choisi', () {
      expect(validerTelephone('6 12 34 56 78', paysParDefaut: 'FR'), isNull);
    });
  });

  group('emailDetaille', () {
    final v = emailDetaille();
    test('accepte une adresse correcte', () {
      expect(v('awa.diop+colis@mail.fr'), isNull);
    });
    test('messages précis', () {
      expect(v(''), 'L\'adresse email est obligatoire');
      expect(v('awa diop@mail.fr'), contains('espace'));
      expect(v('awa.mail.fr'), contains('un @'));
      expect(v('awa@@mail.fr'), contains('seul @'));
      expect(v('@mail.fr'), contains('avant le @ est vide'));
      expect(v('awa@mail'), contains('incomplet'));
      expect(v('awa..diop@mail.fr'), contains('doubler un point'));
    });
  });

  group('noms', () {
    test('prénom avec majuscule initiale, nom en capitales', () {
      expect(normaliserPrenom("jean-pierre n'diaye"), "Jean-Pierre N'Diaye");
      expect(normaliserNomFamille('diop'), 'DIOP');
    });
  });
}
