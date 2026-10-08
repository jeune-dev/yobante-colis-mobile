import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/constants/categories.dart';

/// Règles des trois catégories du cahier des charges, et leur relecture
/// depuis `GET /public/categories`.
///
/// Attention : [CategorieColis.appliquerRegles] modifie un état statique ; les
/// tests qui l'appellent sont regroupés à la fin et réappliquent les règles
/// intégrées ensuite.
void main() {
  group('règles intégrées', () {
    test('trois catégories dans l\'ordre', () {
      expect(CategorieColis.toutes.map((c) => c.code), ['documents', 'colis_moyen', 'colis_xxl']);
      expect(CategorieColis.toutes.map((c) => c.numero), [1, 2, 3]);
    });

    test('documents : prix fixe, paiement à la commande, pas de collecte à domicile', () {
      final c = CategorieColis.documents;
      expect(c.surDevis, isFalse);
      expect(c.validationAdmin, isFalse);
      expect(c.paiement, 'a_la_commande');
      expect(c.modesDepot, isNot(contains('enlevement_domicile')));
      expect(c.adresseSenegalDetaillee, isFalse);
    });

    test('colis moyen : 3 photos, adresse sénégalaise détaillée', () {
      final c = CategorieColis.colisMoyen;
      expect(c.photosMin, 3);
      expect(c.paiement, 'a_la_reception');
      expect(c.adresseSenegalDetaillee, isTrue);
    });

    test('colis XXL : sur devis, paiement après acceptation', () {
      final c = CategorieColis.colisXxl;
      expect(c.surDevis, isTrue);
      expect(c.paiement, 'apres_acceptation');
      expect(c.modesDepot, ['point_collecte', 'enlevement_domicile']);
    });

    test('parCode : code inconnu ou null → colis moyen', () {
      expect(CategorieColis.parCode('colis_xxl').numero, 3);
      expect(CategorieColis.parCode('inconnu').code, 'colis_moyen');
      expect(CategorieColis.parCode(null).code, 'colis_moyen');
    });

    test('parcours selon le mode de paiement', () {
      expect(CategorieColis.documents.parcours, contains('paiement immédiat'));
      expect(CategorieColis.colisMoyen.parcours, contains('réception'));
      expect(CategorieColis.colisXxl.parcours, contains('après acceptation'));
    });

    test('chaque mode de dépôt a un libellé et une icône', () {
      final modes = CategorieColis.toutes.expand((c) => c.modesDepot).toSet();
      for (final m in modes) {
        expect(libellesModeDepot[m], isNotNull, reason: m);
        expect(iconesModeDepot[m], isNotNull, reason: m);
      }
    });
  });

  group('appliquerRegles', () {
    final integrees = [
      for (final c in CategorieColis.toutes)
        {
          'code': c.code,
          'numero': c.numero,
          'libelle': c.libelleFr,
          'description': c.descriptionFr,
          'tarification': c.surDevis ? 'sur_devis' : 'grille',
          'validationAdmin': c.validationAdmin,
          'paiement': c.paiement,
          'photosMin': c.photosMin,
          'modesDepot': c.modesDepot,
          'adresseSenegalDetaillee': c.adresseSenegalDetaillee,
        },
    ];
    tearDown(() => CategorieColis.appliquerRegles(integrees));

    test('remplace les règles, trie par numéro et garde icône et exemples locaux', () {
      final iconeXxl = CategorieColis.colisXxl.icone;
      final exemplesXxl = CategorieColis.colisXxl.exemplesFr;

      CategorieColis.appliquerRegles([
        {'code': 'colis_xxl', 'numero': 3, 'tarification': 'sur_devis', 'photosMin': 4},
        {'code': 'documents', 'numero': 1, 'tarification': 'grille', 'modesDepot': ['point_collecte']},
      ]);

      expect(CategorieColis.toutes.map((c) => c.code), ['documents', 'colis_xxl']);
      expect(CategorieColis.colisXxl.photosMin, 4);
      expect(CategorieColis.colisXxl.icone, iconeXxl);
      expect(CategorieColis.colisXxl.exemplesFr, exemplesXxl);
      expect(CategorieColis.documents.modesDepot, ['point_collecte']);
      // Champs absents : valeurs intégrées de la catégorie
      expect(CategorieColis.documents.paiement, 'a_la_commande');
    });

    test('catégorie absente de la réponse : parCode retombe sur la première dispo', () {
      CategorieColis.appliquerRegles([
        {'code': 'documents', 'numero': 1},
      ]);
      expect(CategorieColis.parCode('colis_moyen').code, 'colis_moyen');
    });

    test('réponse vide ou invalide : règles inchangées', () {
      final avant = CategorieColis.toutes;
      CategorieColis.appliquerRegles([]);
      CategorieColis.appliquerRegles(['pas une map', {'numero': 1}]);
      expect(CategorieColis.toutes, same(avant));
    });
  });
}
