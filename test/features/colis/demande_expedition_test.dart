import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/colis/domain/entities/demande_expedition.dart';

/// Corps envoyés au backend pour le devis (JSON) et la déclaration (multipart).
void main() {
  const base = DemandeExpedition(
    categorie: 'colis_moyen',
    villeDepartId: 'v-paris',
    villeArriveeId: 'v-dakar',
    expediteurNom: '  Awa Diop  ',
    expediteurTelephone: '+33612345678',
    destinataireNom: 'Moussa Ndiaye',
    destinataireTelephone: '+221771234567',
  );

  group('versDevis', () {
    test('champs toujours présents', () {
      final d = base.versDevis();
      expect(d['villeDepartId'], 'v-paris');
      expect(d['villeArriveeId'], 'v-dakar');
      expect(d['categorie'], 'colis_moyen');
      expect(d['modeDepot'], 'point_collecte');
      expect(d['modeLivraison'], 'livraison_domicile');
      expect(d['deviseValeur'], 'EUR');
      expect(d['incoterm'], 'DAP');
      expect(d['payeur'], 'expediteur');
      expect(d['fragile'], isFalse);
      expect(d.containsKey('valeurDeclaree'), isFalse);
      expect(d.containsKey('articles'), isFalse);
      expect(d.containsKey('pieces'), isFalse);
      expect(d.containsKey('poidsKg'), isFalse);
    });

    test('les pièces priment sur le poids global', () {
      final d = DemandeExpedition(
        categorie: 'colis_xxl',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        poidsKg: 50,
        pieces: const [PieceDeclaree(poidsKg: 35, longueurCm: 100)],
      ).versDevis();
      expect(d['pieces'], [
        {'poidsKg': 35.0, 'longueurCm': 100.0, 'typeEmballage': 'carton'},
      ]);
      expect(d.containsKey('poidsKg'), isFalse);
    });

    test('poids global sans pièces, articles, emballages à quantité > 0', () {
      final d = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        poidsKg: 8,
        valeurDeclaree: 300,
        articles: [ArticleChoisi(articleTarifId: 'art1', libelle: 'Valise', quantite: 2)],
        emballages: {'emb1': 1, 'emb2': 0},
      ).versDevis();
      expect(d['poidsKg'], 8);
      expect(d['valeurDeclaree'], 300);
      expect(d['articles'], [
        {'articleTarifId': 'art1', 'quantite': 2},
      ]);
      expect(d['emballages'], [
        {'emballageId': 'emb1', 'quantite': 1},
      ]);
    });
  });

  group('versFormulaire', () {
    test('noms nettoyés, booléens en chaîne, champs vides retirés', () {
      final f = base.versFormulaire();
      expect(f['expediteurNom'], 'Awa Diop');
      expect(f['fragile'], 'false');
      expect(f['conditionsAcceptees'], 'false');
      expect(f['optionColissimo'], 'false');
      expect(f.values, isNot(contains(null)));
      expect(f.containsKey('serviceId'), isFalse);
      expect(f.containsKey('expediteurEmail'), isFalse);
    });

    test('valeur déclarée obligatoire en catégorie 2, même à 0', () {
      expect(base.versFormulaire()['valeurDeclaree'], '0.0');
    });

    test('valeur déclarée jamais envoyée pour des documents', () {
      final f = const DemandeExpedition(
        categorie: 'documents',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        valeurDeclaree: 50,
      ).versFormulaire();
      expect(f.containsKey('valeurDeclaree'), isFalse);
    });

    test('colis XXL : valeur déclarée seulement si > 0', () {
      const xxl = DemandeExpedition(categorie: 'colis_xxl', villeDepartId: 'a', villeArriveeId: 'b');
      expect(xxl.versFormulaire().containsKey('valeurDeclaree'), isFalse);
      const xxlValeur =
          DemandeExpedition(categorie: 'colis_xxl', villeDepartId: 'a', villeArriveeId: 'b', valeurDeclaree: 900);
      expect(xxlValeur.versFormulaire()['valeurDeclaree'], '900.0');
    });

    test('dépôt en point de collecte : point conservé, adresse et tournée ignorées', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        modeDepot: 'point_collecte',
        pointCollecteDepartId: 'pc1',
        adresseDepart: '1 rue X',
        tourneeCollecteId: 't1',
      ).versFormulaire();
      expect(f['pointCollecteDepartId'], 'pc1');
      expect(f.containsKey('adresseDepart'), isFalse);
      expect(f.containsKey('tourneeCollecteId'), isFalse);
    });

    test('collecte à domicile : adresse, tournée et infos de collecte envoyées', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        modeDepot: 'enlevement_domicile',
        pointCollecteDepartId: 'pc1',
        adresseDepart: ' 1 rue X ',
        tourneeCollecteId: 't1',
        infosCollecte: {'datePrevue': '2026-10-10'},
      ).versFormulaire();
      expect(f.containsKey('pointCollecteDepartId'), isFalse);
      expect(f['adresseDepart'], '1 rue X');
      expect(f['tourneeCollecteId'], 't1');
      expect(jsonDecode(f['infosCollecte'] as String), {'datePrevue': '2026-10-10'});
    });

    test('option Colissimo uniquement pour un envoi postal', () {
      const postal = DemandeExpedition(
        categorie: 'documents',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        modeDepot: 'envoi_postal',
        optionColissimo: true,
      );
      expect(postal.versFormulaire()['optionColissimo'], 'true');

      const pointCollecte = DemandeExpedition(
        categorie: 'documents',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        optionColissimo: true,
      );
      expect(pointCollecte.versFormulaire()['optionColissimo'], 'false');
    });

    test('livraison en point de retrait : point conservé, code postal ignoré', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        modeLivraison: 'point_retrait',
        pointRetraitId: 'pr1',
        codePostalArrivee: '12000',
      ).versFormulaire();
      expect(f['pointRetraitId'], 'pr1');
      expect(f.containsKey('codePostalArrivee'), isFalse);
    });

    test('livraison à domicile : point de retrait ignoré, code postal envoyé', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        pointRetraitId: 'pr1',
        codePostalArrivee: '12000',
      ).versFormulaire();
      expect(f.containsKey('pointRetraitId'), isFalse);
      expect(f['codePostalArrivee'], '12000');
    });

    test('tableaux encodés en JSON, poids global avec son emballage', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        poidsKg: 7.5,
        typeEmballage: 'sac',
        articles: [ArticleChoisi(articleTarifId: 'art1', libelle: 'Sac')],
        contenu: [ContenuDeclare(designation: 'Chaussures', quantite: 2, unite: 'paire', valeurUnitaire: 40)],
        emballages: {'emb1': 2},
      ).versFormulaire();
      expect(f['poidsKg'], '7.5');
      expect(f['typeEmballage'], 'sac');
      expect(jsonDecode(f['articles'] as String), [
        {'articleTarifId': 'art1', 'quantite': 1},
      ]);
      expect(jsonDecode(f['articlesDouane'] as String), [
        {'designation': 'Chaussures', 'quantite': 2.0, 'unite': 'paire', 'valeurUnitaire': 40.0},
      ]);
      expect(jsonDecode(f['emballages'] as String), [
        {'emballageId': 'emb1', 'quantite': 2},
      ]);
    });

    test('pièces déclarées : pas de poids global', () {
      final f = const DemandeExpedition(
        categorie: 'colis_xxl',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        poidsKg: 40,
        typeEmballage: 'palette',
        pieces: [PieceDeclaree(poidsKg: 40)],
      ).versFormulaire();
      expect(f.containsKey('poidsKg'), isFalse);
      expect(f.containsKey('typeEmballage'), isFalse);
      expect(jsonDecode(f['pieces'] as String), hasLength(1));
    });

    test('textes facultatifs vides ou blancs non envoyés', () {
      final f = const DemandeExpedition(
        categorie: 'colis_moyen',
        villeDepartId: 'a',
        villeArriveeId: 'b',
        description: '   ',
        referenceClient: '',
        destinataireQuartier: ' Médina ',
      ).versFormulaire();
      expect(f.containsKey('description'), isFalse);
      expect(f.containsKey('referenceClient'), isFalse);
      expect(f['destinataireQuartier'], 'Médina');
    });
  });

  group('ContenuDeclare.toJson', () {
    test('pays d\'origine en majuscules, champs optionnels vides omis', () {
      final json = const ContenuDeclare(
        designation: 'Téléphone',
        codeSh: '',
        paysOrigine: 'cn',
        poidsNetKg: 0.2,
        marque: '',
      ).toJson();
      expect(json['paysOrigine'], 'CN');
      expect(json['poidsNetKg'], 0.2);
      expect(json.containsKey('codeSh'), isFalse);
      expect(json.containsKey('marque'), isFalse);
      expect(json.containsKey('etat'), isFalse);
    });
  });

  test('copyWith ne change que service, simulation et conditions', () {
    final copie = base.copyWith(serviceId: 's1', simulationId: 'sim1', conditionsAcceptees: true);
    expect(copie.serviceId, 's1');
    expect(copie.simulationId, 'sim1');
    expect(copie.conditionsAcceptees, isTrue);
    expect(copie.expediteurNom, base.expediteurNom);
    expect(copie.villeArriveeId, base.villeArriveeId);
    expect(base.copyWith(), base);
  });

  test('les types d\'emballage reprennent ceux du backend', () {
    expect(kTypesEmballage.keys, containsAll(['carton', 'valise', 'barigot', 'palette', 'autre']));
    expect(const PieceDeclaree(poidsKg: 1).typeEmballage, 'carton');
    expect(kTypesEmballage.containsKey(const PieceDeclaree(poidsKg: 1).typeEmballage), isTrue);
  });
}
