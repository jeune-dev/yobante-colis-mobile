// Test d'intégration de la couche données contre un backend réel.
//
// Il n'est exécuté que si la variable d'environnement API_TEST_URL est définie :
//   API_TEST_URL=http://localhost:3000 ADMIN_EMAIL=… ADMIN_PASSWORD=… flutter test test/integration
// Le backend doit avoir la confirmation d'email désactivée (paramètre
// verification_email_obligatoire) et des données de référence (npm run seed).
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/account/data/datasources/espace_client_remote_datasource.dart';
import 'package:yobante_colis/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:yobante_colis/features/catalogue/data/catalogue_remote_datasource.dart';
import 'package:yobante_colis/features/catalogue/domain/catalogue_entities.dart';
import 'package:yobante_colis/features/colis/data/datasources/colis_remote_datasource.dart';
import 'package:yobante_colis/features/colis/domain/entities/demande_expedition.dart';
import 'package:yobante_colis/features/paiements/data/datasources/paiements_remote_datasource.dart';

void main() {
  final url = Platform.environment['API_TEST_URL'];
  final ignorer = url == null ? 'API_TEST_URL non défini' : null;

  String? jeton;
  late Dio dio;
  late CatalogueRemoteDataSource catalogue;
  late ColisRemoteDataSource colis;
  late VilleDesservie paris;
  late VilleDesservie dakar;
  late ServiceExpedition maritime;
  late File photo;
  final suffixe = Random().nextInt(9000000) + 1000000;
  final telephone = '+33612${suffixe.toString().substring(0, 6)}';

  setUpAll(() async {
    if (ignorer != null) return;
    dio = Dio(BaseOptions(baseUrl: url!, headers: {'Accept': 'application/json'}));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (jeton != null && o.extra['skipAuthInterceptor'] != true) o.headers['Authorization'] = 'Bearer $jeton';
      h.next(o);
    }));
    catalogue = CatalogueRemoteDataSource(dio: dio);
    colis = ColisRemoteDataSourceImpl(dio: dio);
    photo = File('${Directory.systemTemp.path}/yobante_test_$suffixe.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 74, 70, 73, 70, 0, 1, 1, 0, 0, 1, 0xFF, 0xD9]);
  });

  test('catalogue public : villes, services, grille, configuration, accueil', () async {
    final villesFr = await catalogue.getVilles(pays: 'FR');
    final villesSn = await catalogue.getVilles(pays: 'SN');
    paris = villesFr.firstWhere((v) => v.nom == 'Paris');
    dakar = villesSn.firstWhere((v) => v.nom == 'Dakar');
    expect(dakar.zoneTarifDakar, isTrue);

    maritime = (await catalogue.getServices()).firstWhere((s) => s.modeTransport == 'maritime');
    final tarifs = await catalogue.getTarifs(categorie: 'colis_moyen', paysDepart: 'FR');
    expect(tarifs.any((a) => a.code == 'VALISE-23' && a.prixDakar == 40), isTrue);

    final config = await catalogue.getConfiguration();
    expect(config.grilleColissimo, isNotEmpty);
    expect(config.adresseReception['FR'], isNotNull);

    await catalogue.getAccueil();
    await catalogue.getTournees(codePostal: '75011');
    await catalogue.getEmballages(categorie: 'colis_moyen');
    await catalogue.getPoints(pays: 'FR', service: 'depot');
  }, skip: ignorer);

  test('simulation sans compte : grille forfaitaire vers Dakar', () async {
    final tarifs = await catalogue.getTarifs(categorie: 'colis_moyen', paysDepart: 'FR');
    final valise = tarifs.firstWhere((a) => a.code == 'VALISE-23');
    final demande = DemandeExpedition(
      categorie: 'colis_moyen',
      villeDepartId: paris.id,
      villeArriveeId: dakar.id,
      articles: [ArticleChoisi(articleTarifId: valise.id, libelle: valise.libelle, quantite: 2)],
    );
    final resultat = await catalogue.devis(demande.versDevis());
    final offre = resultat.offres.firstWhere((o) => o.service.modeTransport == 'maritime');
    expect(offre.total, 80);
    expect(offre.devise, 'EUR');
    expect(offre.lignesForfait.single.quantite, 2);
    expect(offre.zoneTarifaire, 'dakar');
  }, skip: ignorer);

  test('inscription puis connexion par numéro de téléphone', () async {
    final auth = AuthRemoteDataSourceImpl(dio: dio);
    await auth.register(
      nom: 'Test',
      prenom: 'Mobile',
      email: 'mobile$suffixe@test.fr',
      motDePasse: 'Motdepasse1!',
      telephone: telephone,
      pays: 'FR',
      codePostal: '75011',
    );
    final session = await auth.login(telephone, 'Motdepasse1!');
    jeton = session.accessToken;
    expect(jeton, isNotEmpty);
    expect(session.user.email, 'mobile$suffixe@test.fr');

    final profil = await EspaceClientRemoteDataSource(dio: dio).getProfil();
    expect(profil.codePostal, '75011');
    final parrainage = await EspaceClientRemoteDataSource(dio: dio).getParrainage();
    expect(parrainage.code, isNotNull);
  }, skip: ignorer);

  test('catégorie 1 : déclaration avec photo, facture et lien de paiement', () async {
    final resultat = await colis.creerColis(
      DemandeExpedition(
        categorie: 'documents',
        villeDepartId: paris.id,
        villeArriveeId: dakar.id,
        serviceId: maritime.id,
        typeDocument: 'Acte de naissance',
        modeDepot: 'envoi_postal',
        expediteurNom: 'Mobile Test',
        expediteurTelephone: telephone,
        destinataireNom: 'Awa Diop',
        destinataireTelephone: '+221771234567',
        adresseLivraison: 'Rue 10, Médina',
        conditionsAcceptees: true,
      ),
      photosPaths: [photo.path],
    );
    expect(resultat.colis.categorie, 'documents');
    expect(resultat.colis.statut, 'en_attente');
    expect(resultat.colis.reference, matches(RegExp(r'^PNCO\d{10}[A-Z]{3}01')));
    expect(resultat.colis.montantTotal, 25);
    expect(resultat.factureReference, isNotNull);
    expect(resultat.lienPaiement, isNotNull);
    expect(resultat.adresseReception?['adresse'], '12 rue du Port');

    final detail = await colis.getColisDetail(resultat.colis.id);
    expect(detail.photos.single, startsWith('https://'));
    expect(detail.lienPaiement, isNotNull);
    expect(detail.lignesForfait, isNotEmpty);

    final factures = await PaiementsRemoteDataSourceImpl(dio: dio).getFactures();
    final facture = factures.firstWhere((f) => f.colisId == resultat.colis.id);
    expect(facture.devise, 'EUR');
    expect(facture.montantTotal, 25);
    expect(facture.lienPaiement, isNotNull);
  }, skip: ignorer);

  test('catégorie 2 : collecte, 3 photos, adresse sénégalaise, modification', () async {
    final tarifs = await catalogue.getTarifs(categorie: 'colis_moyen', paysDepart: 'FR');
    final valise = tarifs.firstWhere((a) => a.code == 'VALISE-23');
    final base = DemandeExpedition(
      categorie: 'colis_moyen',
      villeDepartId: paris.id,
      villeArriveeId: dakar.id,
      serviceId: maritime.id,
      etatMarchandise: 'neuf',
      valeurDeclaree: 300,
      description: 'Vêtements',
      articles: [ArticleChoisi(articleTarifId: valise.id, libelle: valise.libelle)],
      contenu: const [ContenuDeclare(designation: 'Chaussures', quantite: 2, valeurUnitaire: 50, etat: 'neuf')],
      modeDepot: 'enlevement_domicile',
      adresseDepart: '5 rue de Rivoli',
      codePostalDepart: '75001',
      infosCollecte: const {'dateSouhaitee': '2026-10-15', 'heureSouhaitee': '10:00', 'etage': 2, 'ascenseur': true},
      expediteurNom: 'Mobile Test',
      expediteurTelephone: telephone,
      destinataireNom: 'Moussa Fall',
      destinataireTelephone: '+221771234567',
      adresseLivraison: 'Rue 10, Médina',
      destinataireQuartier: 'Médina',
      destinataireArrondissement: 'Dakar Plateau',
      destinataireDepartement: 'Dakar',
      destinatairePointRepere: 'Face à la mosquée',
      conditionsAcceptees: true,
    );
    final resultat = await colis.creerColis(base, photosPaths: [photo.path, photo.path, photo.path]);
    expect(resultat.colis.statut, 'en_attente_validation');
    expect(resultat.factureReference, isNull);

    final detail = await colis.getColisDetail(resultat.colis.id);
    expect(detail.modifiable, isTrue);
    expect(detail.dateCollecte, '2026-10-15');
    expect(detail.infosCollecte['etage'], 2);
    expect(detail.destinataireQuartier, 'Médina');

    final modifie = (await colis.modifierColis(detail.id, {'destinatairePointRepere': 'Près du marché'})).valeur;
    expect(modifie.destinatairePointRepere, 'Près du marché');
  }, skip: ignorer);

  test('catégorie 3 : proposition de l\'administrateur puis acceptation', () async {
    final resultat = await colis.creerColis(
      DemandeExpedition(
        categorie: 'colis_xxl',
        villeDepartId: paris.id,
        villeArriveeId: dakar.id,
        serviceId: maritime.id,
        description: 'Réfrigérateur',
        pieces: const [PieceDeclaree(poidsKg: 90, longueurCm: 180, largeurCm: 80, hauteurCm: 70)],
        modeDepot: 'enlevement_domicile',
        adresseDepart: '5 rue de Rivoli',
        codePostalDepart: '75001',
        infosCollecte: const {'dateSouhaitee': '2026-10-16'},
        expediteurNom: 'Mobile Test',
        expediteurTelephone: telephone,
        destinataireNom: 'Moussa Fall',
        destinataireTelephone: '+221771234567',
        adresseLivraison: 'Rue 10, Médina',
        destinataireQuartier: 'Médina',
        destinataireArrondissement: 'Dakar Plateau',
        destinataireDepartement: 'Dakar',
        destinatairePointRepere: 'Face à la mosquée',
        conditionsAcceptees: true,
      ),
      photosPaths: [photo.path],
    );
    expect(resultat.colis.montantEnAttente, isTrue);

    // L'administrateur propose un prix (back-office)
    final admin = await dio.post('/auth/login',
        data: {
          'identifiant': Platform.environment['ADMIN_EMAIL'] ?? 'admin@test.local',
          'password': Platform.environment['ADMIN_PASSWORD'] ?? 'Admin_Test_1234!',
        },
        options: Options(extra: {'skipAuthInterceptor': true}));
    await dio.post('/admin/colis/${resultat.colis.id}/proposition',
        data: {'montantTotal': 180, 'commentaire': 'Emballage inclus'},
        options: Options(headers: {'Authorization': 'Bearer ${admin.data['data']['accessToken']}'},
            extra: {'skipAuthInterceptor': true}));

    final propose = await colis.getColisDetail(resultat.colis.id);
    expect(propose.statut, 'devis_propose');
    expect(propose.montantPropose, 180);
    expect(propose.propositionCommentaire, 'Emballage inclus');

    final acceptation = await colis.accepterProposition(resultat.colis.id);
    expect(acceptation.colis.statut, 'en_attente');
    expect(acceptation.factureReference, isNotNull);
    expect(acceptation.lienPaiement, isNotNull);

    final suivi = await colis.getSuiviColis(resultat.colis.id);
    expect(suivi.map((e) => e.code), containsAll(['SOUMIS', 'DEVIS_PROPOSE', 'DEVIS_ACCEPTE']));
  }, skip: ignorer);

  test('listes : envoyés et reçus', () async {
    final envoyes = await colis.getColis();
    expect((envoyes['colis'] as List).length, greaterThanOrEqualTo(3));
    await colis.getColisRecus();
  }, skip: ignorer);
}
