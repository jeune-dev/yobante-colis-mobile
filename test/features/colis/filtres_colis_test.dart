import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/colis/domain/entities/filtres_colis.dart';

void main() {
  group('FiltresColis.versRequete', () {
    test('aucun filtre : requête vide et inactive', () {
      const f = FiltresColis();
      expect(f.versRequete(), isEmpty);
      expect(f.actif, isFalse);
    });

    test('colis envoyés : tous les filtres, référence nettoyée, fin de journée incluse', () {
      final f = FiltresColis(
        reference: '  ybc-01 ',
        categorie: 'documents',
        enCours: true,
        dateDebut: DateTime(2026, 1, 5),
        dateFin: DateTime(2026, 2, 9, 15, 30),
      );
      expect(f.versRequete(), {
        'reference': 'ybc-01',
        'categorie': 'documents',
        'enCours': 'true',
        'dateDebut': '2026-01-05',
        'dateFin': '2026-02-09T23:59:59',
      });
    });

    test('colis reçus : seule la période est transmise', () {
      final f = FiltresColis(
        reference: 'YBC',
        categorie: 'colis_xxl',
        enCours: true,
        dateDebut: DateTime(2026, 3, 1),
      );
      expect(f.versRequete(recus: true), {'dateDebut': '2026-03-01'});
    });

    test('référence vide ou blanche ignorée et non active', () {
      const f = FiltresColis(reference: '   ');
      expect(f.versRequete(), isEmpty);
      expect(f.actif, isFalse);
    });
  });

  group('FiltresColis.actif', () {
    test('vrai dès qu\'un filtre est posé', () {
      expect(const FiltresColis(reference: 'A').actif, isTrue);
      expect(const FiltresColis(categorie: 'documents').actif, isTrue);
      expect(const FiltresColis(enCours: true).actif, isTrue);
      expect(FiltresColis(dateDebut: DateTime(2026)).actif, isTrue);
      expect(FiltresColis(dateFin: DateTime(2026)).actif, isTrue);
    });
  });

  group('FiltresColis.copyWith', () {
    final plein = FiltresColis(
      reference: 'R',
      categorie: 'documents',
      enCours: true,
      dateDebut: DateTime(2026, 1, 1),
      dateFin: DateTime(2026, 1, 31),
    );

    test('conserve les valeurs non fournies', () {
      expect(plein.copyWith(), plein);
      expect(plein.copyWith(enCours: false).categorie, 'documents');
    });

    test('effacerCategorie et effacerPeriode remettent à null', () {
      final sansCategorie = plein.copyWith(effacerCategorie: true);
      expect(sansCategorie.categorie, isNull);
      expect(sansCategorie.dateDebut, isNotNull);

      final sansPeriode = plein.copyWith(effacerPeriode: true);
      expect(sansPeriode.dateDebut, isNull);
      expect(sansPeriode.dateFin, isNull);
      expect(sansPeriode.categorie, 'documents');
    });
  });
}
