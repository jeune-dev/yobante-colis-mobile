import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/colis/data/models/colis_model.dart';
import 'package:yobante_colis/features/colis/domain/entities/colis.dart';

/// Désérialisation des expéditions telles que renvoyées par le backend.
void main() {
  group('versDouble', () {
    test('accepte nombres, chaînes décimales PostgreSQL et null', () {
      expect(versDouble(null), isNull);
      expect(versDouble(5), 5.0);
      expect(versDouble(2.5), 2.5);
      expect(versDouble('5.000'), 5.0);
      expect(versDouble('abc'), isNull);
    });
  });

  group('ColisModel.fromJson', () {
    final complet = <String, dynamic>{
      'id': 'c1',
      'reference': 'YBC-0001',
      'service': {'id': 's1', 'code': 'EXP', 'nom': 'Express'},
      'typeContenu': 'cadeau',
      'fragile': true,
      'expediteurNom': 'Awa Diop',
      'expediteurTelephone': '+33612345678',
      'paysDepart': 'FR',
      'villeDepart': {'id': 'v-paris', 'nom': 'Paris', 'pays': 'FR'},
      'destinataireNom': 'Moussa Ndiaye',
      'destinataireTelephone': '+221771234567',
      'paysArrivee': 'SN',
      'villeArrivee': {'id': 'v-dakar', 'nom': 'Dakar', 'pays': 'SN'},
      'pointRetrait': {'id': 'p1', 'nom': 'Agence Plateau', 'horaires': {'lun': '9h-18h'}},
      'nbPieces': 2,
      'poidsReelKg': '12.500',
      'poidsFactureKg': 14,
      'pieces': [
        {'id': 'pc1', 'poidsKg': '6.5', 'longueurCm': 40},
        {'id': 'pc2', 'poidsKg': 6, 'typeEmballage': 'valise'},
      ],
      'montantTotal': '45000.00',
      'statut': 'en_transit',
      'photos': [
        {'url': 'https://cdn/1.jpg', 'publicId': 'x'},
        'https://cdn/ancienne.jpg',
      ],
      'enRetard': true,
      'createdAt': '2026-09-01T10:00:00.000Z',
      'categorie': 'colis_moyen',
      'lignesForfait': [
        {'libelle': 'Valise 23 kg', 'quantite': 2, 'prixUnitaire': '30', 'montant': '60', 'devise': 'EUR'},
      ],
      'infosCollecte': {'datePrevue': '2026-09-03'},
      'facture': {'reference': 'FAC-1', 'statut': 'impayee'},
      'tourneeCollecte': {'titre': 'Tournée Île-de-France', 'dateCollecte': '2026-09-05'},
      'modifiable': true,
      'lienPaiement': 'https://pay/1',
    };

    test('lit les champs simples, imbriqués et les décimaux en chaîne', () {
      final c = ColisModel.fromJson(complet);

      expect(c.id, 'c1');
      expect(c.reference, 'YBC-0001');
      expect(c.service, const ServiceRef(id: 's1', code: 'EXP', nom: 'Express'));
      expect(c.service!.nom, 'Express');
      expect(c.typeContenu, 'cadeau');
      expect(c.fragile, isTrue);
      expect(c.villeDepart!.nom, 'Paris');
      expect(c.villeArrivee!.pays, 'SN');
      expect(c.pointRetrait!.horaires, {'lun': '9h-18h'});
      expect(c.poidsReelKg, 12.5);
      expect(c.poidsFactureKg, 14.0);
      expect(c.montantTotal, 45000.0);
      expect(c.statut, 'en_transit');
      expect(c.enRetard, isTrue);
      expect(c.createdAt, DateTime.utc(2026, 9, 1, 10));
      expect(c.modifiable, isTrue);
      expect(c.lienPaiement, 'https://pay/1');
    });

    test('reprend l\'id de la ville imbriquée quand villeXxxId est absent', () {
      final c = ColisModel.fromJson(complet);
      expect(c.villeDepartId, 'v-paris');
      expect(c.villeArriveeId, 'v-dakar');
    });

    test('pièces et lignes de forfait sont converties', () {
      final c = ColisModel.fromJson(complet);
      expect(c.pieces, hasLength(2));
      expect(c.pieces.first.poidsKg, 6.5);
      expect(c.pieces.first.longueurCm, 40.0);
      expect(c.pieces.first.typeEmballage, 'carton');
      expect(c.pieces.last.typeEmballage, 'valise');
      expect(c.lignesForfait.single.quantite, 2);
      expect(c.lignesForfait.single.montant, 60.0);
      expect(c.lignesForfait.single.devise, 'EUR');
    });

    test('photos : objets { url, publicId } et anciennes URL simples', () {
      final c = ColisModel.fromJson(complet);
      expect(c.photos, ['https://cdn/1.jpg', 'https://cdn/ancienne.jpg']);
    });

    test('facture, tournée et date de collecte sont aplaties', () {
      final c = ColisModel.fromJson(complet);
      expect(c.factureReference, 'FAC-1');
      expect(c.factureStatut, 'impayee');
      expect(c.tourneeTitre, 'Tournée Île-de-France');
      // infosCollecte.datePrevue prime sur la date de la tournée
      expect(c.dateCollecte, '2026-09-03');
    });

    test('date de collecte : repli sur l\'enlèvement puis sur la tournée', () {
      final avecEnlevement = ColisModel.fromJson({
        'enlevement': {'dateSouhaitee': '2026-10-01'},
        'tourneeCollecte': {'dateCollecte': '2026-10-02'},
      });
      expect(avecEnlevement.dateCollecte, '2026-10-01');

      final tourneeSeule = ColisModel.fromJson({
        'tourneeCollecte': {'dateCollecte': '2026-10-02'},
      });
      expect(tourneeSeule.dateCollecte, '2026-10-02');
    });

    test('JSON minimal : valeurs par défaut sans planter', () {
      final c = ColisModel.fromJson(const {});

      expect(c.id, '');
      expect(c.statut, 'en_attente');
      expect(c.typeContenu, 'marchandise');
      expect(c.modeDepot, 'point_collecte');
      expect(c.modeLivraison, 'point_retrait');
      expect(c.nbPieces, 1);
      expect(c.devise, 'XOF');
      expect(c.incoterm, 'DAP');
      expect(c.payeur, 'expediteur');
      expect(c.categorie, 'colis_moyen');
      expect(c.photos, isEmpty);
      expect(c.pieces, isEmpty);
      expect(c.lignesForfait, isEmpty);
      expect(c.infosCollecte, isEmpty);
      expect(c.montantPropose, isNull);
      expect(c.dateCollecte, isNull);
    });

    test('date de création illisible : repli sur maintenant', () {
      final avant = DateTime.now();
      final c = ColisModel.fromJson(const {'createdAt': 'pas une date'});
      expect(c.createdAt.isBefore(avant), isFalse);
    });
  });

  group('Colis — règles métier', () {
    Colis colis({String categorie = 'colis_moyen', double montant = 0, String? depart, String? arrivee}) =>
        ColisModel.fromJson({
          'categorie': categorie,
          'montantTotal': montant,
          'paysDepart': ?depart,
          'paysArrivee': ?arrivee,
        });

    test('montantEnAttente : seulement un colis XXL sans montant arrêté', () {
      expect(colis(categorie: 'colis_xxl').montantEnAttente, isTrue);
      expect(colis(categorie: 'colis_xxl', montant: 150000).montantEnAttente, isFalse);
      expect(colis(categorie: 'colis_moyen').montantEnAttente, isFalse);
      expect(colis(categorie: 'documents').montantEnAttente, isFalse);
    });

    test('estInternational : pays de départ et d\'arrivée connus et différents', () {
      expect(colis(depart: 'FR', arrivee: 'SN').estInternational, isTrue);
      expect(colis(depart: 'SN', arrivee: 'SN').estInternational, isFalse);
      expect(colis(depart: 'FR').estInternational, isFalse);
      expect(colis().estInternational, isFalse);
    });

    test('égalité Equatable sur id, référence et statut', () {
      final a = ColisModel.fromJson(const {'id': '1', 'reference': 'R', 'statut': 'livre', 'fragile': true});
      final b = ColisModel.fromJson(const {'id': '1', 'reference': 'R', 'statut': 'livre'});
      final c = ColisModel.fromJson(const {'id': '1', 'reference': 'R', 'statut': 'en_transit'});
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('ColisPiece.toJson', () {
    test('omet les champs vides', () {
      expect(const ColisPiece(poidsKg: 3).toJson(), {'typeEmballage': 'carton', 'poidsKg': 3.0});
      expect(const ColisPiece(poidsKg: 3, designation: '').toJson().containsKey('designation'), isFalse);
    });

    test('conserve désignation et dimensions renseignées', () {
      final json = const ColisPiece(
        poidsKg: 10,
        designation: 'Valise',
        typeEmballage: 'valise',
        longueurCm: 70,
        largeurCm: 45,
        hauteurCm: 30,
      ).toJson();
      expect(json, {
        'designation': 'Valise',
        'typeEmballage': 'valise',
        'poidsKg': 10.0,
        'longueurCm': 70.0,
        'largeurCm': 45.0,
        'hauteurCm': 30.0,
      });
    });
  });

  group('SuiviEvenement.fromJson', () {
    test('accepte les clés code / date', () {
      final e = SuiviEvenement.fromJson(const {
        'code': 'ARR',
        'statut': 'arrive',
        'libelle': 'Arrivé à Dakar',
        'lieu': 'Dakar',
        'date': '2026-09-10T08:00:00Z',
      });
      expect(e.code, 'ARR');
      expect(e.libelle, 'Arrivé à Dakar');
      expect(e.date, DateTime.utc(2026, 9, 10, 8));
    });

    test('accepte les clés codeEvenement / dateEvenement', () {
      final e = SuiviEvenement.fromJson(const {
        'codeEvenement': 'DEP',
        'statut': 'expedie',
        'dateEvenement': '2026-09-08T08:00:00Z',
      });
      expect(e.code, 'DEP');
      expect(e.libelle, '');
      expect(e.date, DateTime.utc(2026, 9, 8, 8));
    });
  });

  test('VilleRef, ServiceRef et PointRef : égalité sur l\'id', () {
    expect(const VilleRef(id: 'v', nom: 'Dakar'), const VilleRef(id: 'v', nom: 'Autre'));
    expect(const ServiceRef(id: 's', code: 'A', nom: 'A'), const ServiceRef(id: 's', code: 'B', nom: 'B'));
    expect(const PointRef(id: 'p', nom: 'A'), isNot(const PointRef(id: 'q', nom: 'A')));
  });
}
