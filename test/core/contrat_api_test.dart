import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/core/constants/categories.dart';
import 'package:yobnate_colis/core/services/mesure_audience.dart';
import 'package:yobnate_colis/core/services/version_service.dart';
import 'package:yobnate_colis/features/adresses/data/adresses_remote_datasource.dart';
import 'package:yobnate_colis/features/avis/data/avis_remote_datasource.dart';
import 'package:yobnate_colis/features/enlevements/data/enlevements_remote_datasource.dart';
import 'package:yobnate_colis/features/paiements/domain/entities/reglement.dart';

/// Lecture des réponses réelles du contrat d'API mobile (CONTRAT-API-MOBILE.md).
void main() {
  test('catégories : les règles du backend remplacent les valeurs intégrées', () {
    CategorieColis.appliquerRegles([
      {
        'code': 'documents',
        'numero': 1,
        'libelle': 'Documents',
        'tarification': 'forfait',
        'validationAdmin': false,
        'paiement': 'a_la_commande',
        'photosMin': 2,
        'modesDepot': ['point_collecte'],
        'adresseSenegalDetaillee': false,
      },
    ]);
    expect(CategorieColis.documents.photosMin, 2);
    expect(CategorieColis.documents.modesDepot, ['point_collecte']);
    // Catégorie absente de la réponse : repli sur la valeur intégrée
    expect(CategorieColis.parCode('colis_xxl').code, anyOf('colis_xxl', 'documents', 'colis_moyen'));
  });

  test('version : comparaison sémantique', () {
    expect(VersionService.comparer('1.0.0', '1.2.0'), lessThan(0));
    expect(VersionService.comparer('1.10.0', '1.9.3'), greaterThan(0));
    expect(VersionService.comparer('1.2.0+5', '1.2.0'), 0);
  });

  test('identifiant visiteur : UUID v4', () {
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(genererUuidV4()),
      isTrue,
    );
  });

  test('adresse du carnet', () {
    final a = AdresseCarnet.fromJson({
      'id': '6e0fd49f-0e19-4c25-b19c-20dcf5ac21f7',
      'libelle': 'Maman à Dakar',
      'type': 'destinataire',
      'nom': 'Moussa Fall',
      'telephone': '+221771234567',
      'pays': 'SN',
      'villeId': '0f40e346-0b07-4735-92f9-fb682bbbc0cb',
      'adresse': 'Rue 10, Médina',
      'quartier': 'Médina',
      'pointRepere': 'Face à la mosquée',
      'parDefaut': true,
      'ville': {'id': '0f40e346-0b07-4735-92f9-fb682bbbc0cb', 'nom': 'Thiès', 'pays': 'SN'},
    });
    expect(a.villeNom, 'Thiès');
    expect(a.parDefaut, isTrue);
    expect(a.estDestinataire && !a.estExpediteur, isTrue);
  });

  test('demande d\'enlèvement', () {
    final d = DemandeEnlevement.fromJson({
      'id': 'a64faba9-0db2-4767-90a8-695b3c577821',
      'reference': 'ENL-2026-00099',
      'contactNom': 'Awa Diop',
      'contactTelephone': '+33612340002',
      'pays': 'FR',
      'villeId': 'c6ee37a4-b2ce-427a-b4ef-4d9c77207284',
      'adresse': '10 rue de la Paix',
      'dateSouhaitee': '2026-10-12',
      'creneau': '08:00-12:00',
      'nbColis': 2,
      'statut': 'demande',
      'fraisEnlevement': '0.00',
      'ville': {'nom': 'Paris'},
      'colis': {'reference': 'PNCO0126092026ADI02'},
      'createdAt': '2026-09-26T16:32:43.821Z',
    });
    expect(d.modifiable && d.annulable, isTrue);
    expect(d.fraisEnlevement, 0);
    expect(d.colisReference, 'PNCO0126092026ADI02');
  });

  test('encours et avis', () {
    final e = Encours.fromJson({'nbFacturesImpayees': 3, 'parDevise': {'EUR': 245}, 'facturesEchues': []});
    expect(e.parDevise['EUR'], 245);
    final s = SyntheseAvis.fromJson({
      'total': 1,
      'noteMoyenne': 5,
      'repartition': [
        {'note': 5, 'total': 1},
      ],
    });
    expect(s.repartition[5], 1);
    final a = Avis.fromJson({'id': 'x', 'note': 5, 'auteur': 'Papa N.', 'date': '2026-09-26T16:30:09.948Z'});
    expect(a.auteur, 'Papa N.');
  });
}
