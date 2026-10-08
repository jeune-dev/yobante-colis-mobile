import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/colis/domain/entities/demande_expedition.dart';
import 'package:yobante_colis/features/colis/domain/entities/filtres_colis.dart';

/// Champs envoyés au backend : noms et valeurs attendus par ses schémas Joi
/// (un champ inconnu y est retiré sans erreur, d'où ces vérifications).
void main() {
  group('filtres des listes de colis', () {
    test('envois : référence, catégorie, en cours et période', () {
      final q = FiltresColis(
        reference: ' PNCO01 ',
        categorie: 'colis_moyen',
        enCours: true,
        dateDebut: DateTime(2026, 9, 1),
        dateFin: DateTime(2026, 9, 30),
      ).versRequete();
      expect(q, {
        'reference': 'PNCO01',
        'categorie': 'colis_moyen',
        'enCours': 'true',
        'dateDebut': '2026-09-01',
        'dateFin': '2026-09-30T23:59:59',
      });
    });

    test('colis reçus : seule la période est transmise', () {
      final q = FiltresColis(reference: 'X', categorie: 'documents', enCours: true, dateDebut: DateTime(2026, 1, 2))
          .versRequete(recus: true);
      expect(q, {'dateDebut': '2026-01-02'});
    });

    test('sans filtre : aucun paramètre', () {
      expect(const FiltresColis().versRequete(), isEmpty);
      expect(const FiltresColis().actif, isFalse);
    });
  });

  group('déclaration d\'expédition', () {
    const demande = DemandeExpedition(
      categorie: 'colis_moyen',
      villeDepartId: 'a',
      villeArriveeId: 'b',
      marchandiseDangereuse: true,
      pieces: [PieceDeclaree(poidsKg: 4, typeEmballage: 'valise')],
      contenu: [
        ContenuDeclare(
          designation: 'Téléphone',
          quantite: 2,
          unite: 'piece',
          valeurUnitaire: 150,
          codeSh: '851712',
          poidsNetKg: 0.4,
          paysOrigine: 'cn',
          marque: 'Marque',
        ),
      ],
    );

    test('marchandise dangereuse dans le devis et le formulaire', () {
      expect(demande.versDevis()['marchandiseDangereuse'], isTrue);
      expect(demande.versFormulaire()['marchandiseDangereuse'], 'true');
    });

    test('type d\'emballage de chaque pièce', () {
      final pieces = jsonDecode(demande.versFormulaire()['pieces'] as String) as List;
      expect(pieces.single['typeEmballage'], 'valise');
      expect(kTypesEmballage.keys, contains('valise'));
    });

    test('inventaire douanier complet', () {
      final articles = jsonDecode(demande.versFormulaire()['articlesDouane'] as String) as List;
      expect(articles.single, {
        'designation': 'Téléphone',
        'quantite': 2,
        'unite': 'piece',
        'valeurUnitaire': 150,
        'codeSh': '851712',
        'poidsNetKg': 0.4,
        'paysOrigine': 'CN',
        'marque': 'Marque',
      });
    });

    test('colis déclaré au seul poids : emballage au niveau du colis', () {
      const auPoids = DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        poidsKg: 3,
        typeEmballage: 'sac',
      );
      final f = auPoids.versFormulaire();
      expect(f['poidsKg'], '3.0');
      expect(f['typeEmballage'], 'sac');
    });
  });
}
