import 'package:dio/dio.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';
import '../../../core/utils/pagination.dart';
import '../../enlevements/data/enlevements_remote_datasource.dart';

/// Espace du personnel (`/admin/*`) : le backend limite chaque liste au
/// périmètre du compte — enlèvements et livraisons affectés au coursier,
/// colis transitant par le point de l'agent, tout pour un administrateur.

double? _dn(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

String? _nomVille(dynamic v) => (v as Map<String, dynamic>?)?['nom'] as String?;

/// Demande d'enlèvement vue par le personnel : la demande et son contexte de tournée.
class EnlevementTerrain {
  final DemandeEnlevement demande;
  final String? pointDepotNom;
  final String? coursierNom;
  const EnlevementTerrain({required this.demande, this.pointDepotNom, this.coursierNom});

  factory EnlevementTerrain.fromJson(Map<String, dynamic> j) {
    final coursier = j['coursier'] as Map<String, dynamic>?;
    return EnlevementTerrain(
      demande: DemandeEnlevement.fromJson(j),
      pointDepotNom: (j['pointDepot'] as Map<String, dynamic>?)?['nom'] as String?,
      coursierNom: coursier == null ? null : '${coursier['prenom'] ?? ''} ${coursier['nom'] ?? ''}'.trim(),
    );
  }

  /// Le coursier démarre un enlèvement planifié, puis le clôture une fois sur place.
  bool get demarrable => demande.statut == 'planifie';
  bool get cloturable => demande.statut == 'en_cours';
}

/// Événement de suivi que le compte peut enregistrer sur un colis.
class EvenementPossible {
  final String code;
  final String libelle;
  final String? statutInduit;
  const EvenementPossible({required this.code, required this.libelle, this.statutInduit});

  factory EvenementPossible.fromJson(Map<String, dynamic> j) => EvenementPossible(
        code: j['code'] as String? ?? '',
        libelle: j['libelle'] as String? ?? '',
        statutInduit: j['statutInduit'] as String?,
      );

  /// Remise au destinataire : le code de retrait qu'il a reçu est exigé, s'il en a un.
  bool exigeCodeRetrait(ColisTerrain colis) => colis.aCodeRetrait && (code == 'RETIRE' || code == 'LIVRE');

  /// Échec, refus ou incident : le motif est demandé.
  bool get exigeMotif => const ['ENL_ECHEC', 'LIV_ECHEC', 'REFUSE', 'AVARIE'].contains(code);
}

class EtapeSuivi {
  final String libelle;
  final String? date;
  final String? lieu;
  final String? commentaire;
  const EtapeSuivi({required this.libelle, this.date, this.lieu, this.commentaire});

  factory EtapeSuivi.fromJson(Map<String, dynamic> j) => EtapeSuivi(
        libelle: j['libelle'] as String? ?? j['codeEvenement'] as String? ?? '',
        date: j['dateEvenement'] as String? ?? j['createdAt'] as String?,
        lieu: j['lieu'] as String?,
        commentaire: j['commentaire'] as String?,
      );
}

/// Facture du colis, pour l'encaissement au comptoir ou à la livraison.
class FactureTerrain {
  final String id;
  final String reference;
  final String devise;
  final double montantTotal;
  final double montantPaye;
  final String statut;
  const FactureTerrain({
    required this.id,
    required this.reference,
    required this.devise,
    required this.montantTotal,
    required this.montantPaye,
    required this.statut,
  });

  factory FactureTerrain.fromJson(Map<String, dynamic> j) => FactureTerrain(
        id: j['id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        devise: j['devise'] as String? ?? 'XOF',
        montantTotal: _dn(j['montantTotal']) ?? 0,
        montantPaye: _dn(j['montantPaye']) ?? 0,
        statut: j['statut'] as String? ?? '',
      );

  double get reste => (montantTotal - montantPaye).clamp(0, double.infinity).toDouble();
  bool get aEncaisser => reste > 0 && const ['en_attente', 'partiellement_payee'].contains(statut);

  /// Moyens acceptés selon le pays de règlement (même liste que le backend).
  List<String> get methodes => devise == 'EUR'
      ? const ['especes', 'carte', 'virement', 'paypal']
      : const ['especes', 'wave', 'orange_money', 'free_money', 'carte', 'virement'];
}

Map<String, String> get kMethodesPaiement => {
      'especes': tr('Espèces'),
      'wave': 'Wave',
      'orange_money': 'Orange Money',
      'free_money': 'Free Money',
      'carte': tr('Carte bancaire'),
      'virement': tr('Virement'),
      'paypal': 'PayPal',
    };

class ColisTerrain {
  final String id;
  final String reference;
  final String statut;
  final String expediteurNom;
  final String? expediteurTelephone;
  final String destinataireNom;
  final String? destinataireTelephone;
  final String? adresseLivraison;
  final String? villeDepart;
  final String? villeArrivee;
  final String? pointActuel;
  final String? pointRetrait;
  final String? modeLivraison;
  final int nbPieces;
  final double? poidsKg;
  final String? description;
  final String? instructionsLivraison;
  final bool fragile;
  final bool enRetard;
  final bool aCodeRetrait;
  final FactureTerrain? facture;
  final List<EvenementPossible> evenementsPossibles;
  final List<EtapeSuivi> historique;

  const ColisTerrain({
    required this.id,
    required this.reference,
    required this.statut,
    required this.expediteurNom,
    this.expediteurTelephone,
    required this.destinataireNom,
    this.destinataireTelephone,
    this.adresseLivraison,
    this.villeDepart,
    this.villeArrivee,
    this.pointActuel,
    this.pointRetrait,
    this.modeLivraison,
    this.nbPieces = 1,
    this.poidsKg,
    this.description,
    this.instructionsLivraison,
    this.fragile = false,
    this.enRetard = false,
    this.aCodeRetrait = false,
    this.facture,
    this.evenementsPossibles = const [],
    this.historique = const [],
  });

  factory ColisTerrain.fromJson(Map<String, dynamic> j) => ColisTerrain(
        id: j['id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        expediteurNom: j['expediteurNom'] as String? ?? '',
        expediteurTelephone: j['expediteurTelephone'] as String?,
        destinataireNom: j['destinataireNom'] as String? ?? '',
        destinataireTelephone: j['destinataireTelephone'] as String?,
        adresseLivraison: j['adresseLivraison'] as String?,
        villeDepart: _nomVille(j['villeDepart']),
        villeArrivee: _nomVille(j['villeArrivee']),
        pointActuel: _nomVille(j['pointActuel']),
        pointRetrait: _nomVille(j['pointRetrait']),
        modeLivraison: j['modeLivraison'] as String?,
        nbPieces: (j['nbPieces'] as num?)?.toInt() ?? 1,
        poidsKg: _dn(j['poidsVerifieKg']) ?? _dn(j['poidsFactureKg']),
        description: j['description'] as String?,
        instructionsLivraison: j['instructionsLivraison'] as String?,
        fragile: j['fragile'] as bool? ?? false,
        enRetard: j['enRetard'] as bool? ?? false,
        aCodeRetrait: j['aCodeRetrait'] as bool? ?? j['codeRetrait'] != null,
        facture: j['facture'] is Map<String, dynamic> ? FactureTerrain.fromJson(j['facture'] as Map<String, dynamic>) : null,
        evenementsPossibles: (j['evenementsPossibles'] as List? ?? const [])
            .map((e) => EvenementPossible.fromJson(e as Map<String, dynamic>))
            .toList(),
        historique: (j['historique'] as List? ?? const [])
            .map((e) => EtapeSuivi.fromJson(e as Map<String, dynamic>))
            .toList()
            .reversed
            .toList(),
      );
}

class PersonnelRemoteDataSource {
  final Dio dio;
  PersonnelRemoteDataSource({required this.dio});

  // ── Enlèvements ────────────────────────────────────────────────────────────

  Future<List<EnlevementTerrain>> getEnlevements() => appelApi(() async {
        final lignes = await chargerToutesLesPages(dio, Env.personnelEnlevements, 'demandes', maxPages: 5);
        return lignes.map(EnlevementTerrain.fromJson).toList();
      }, tr('Impossible de charger les enlèvements'));

  /// Tournée du jour du coursier connecté (enlèvements planifiés ou en cours).
  Future<List<EnlevementTerrain>> getTourneeDuJour() => appelApi(() async {
        final res = await dio.get(Env.personnelTournee);
        return (res.data['data']['demandes'] as List? ?? const [])
            .map((e) => EnlevementTerrain.fromJson(e as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger la tournée'));

  Future<EnlevementTerrain> getEnlevement(String id) => appelApi(() async {
        final res = await dio.get(Env.personnelEnlevementId(id));
        return EnlevementTerrain.fromJson(res.data['data']['demande'] as Map<String, dynamic>);
      }, tr('Demande introuvable'));

  Future<String> demarrerEnlevement(String id) => appelApi(() async {
        return messageApi(await dio.patch(Env.personnelEnlevementDemarrer(id)), tr('Enlèvement démarré.'));
      }, tr('Impossible de démarrer l\'enlèvement'));

  /// [effectue] : colis récupérés ; sinon échec, avec [motif] obligatoire.
  Future<String> cloturerEnlevement(String id, {required bool effectue, String? motif, String? commentaire}) =>
      appelApi(() async {
        final res = await dio.patch(Env.personnelEnlevementCloturer(id), data: {
          'statut': effectue ? 'effectue' : 'echoue',
          if (!effectue) 'motifEchec': motif?.trim(),
          if (commentaire != null && commentaire.trim().isNotEmpty) 'commentaire': commentaire.trim(),
        });
        return messageApi(res, tr('Enlèvement clôturé.'));
      }, tr('Impossible de clôturer l\'enlèvement'));

  // ── Colis ──────────────────────────────────────────────────────────────────

  Future<List<ColisTerrain>> getColis({List<String> statuts = const []}) => appelApi(() async {
        final res = await dio.get(Env.personnelColis, queryParameters: {
          if (statuts.length == 1) 'statut': statuts.first,
          if (statuts.length > 1) 'statut': statuts,
          'limit': kTaillePageMax,
          'sortOrder': 'asc',
        });
        return (res.data['data']['colis'] as List? ?? const [])
            .map((e) => ColisTerrain.fromJson(e as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger les colis'));

  Future<ColisTerrain> getColisDetail(String id) => appelApi(() async {
        final res = await dio.get(Env.personnelColisId(id));
        return ColisTerrain.fromJson(res.data['data']['colis'] as Map<String, dynamic>);
      }, tr('Expédition introuvable'));

  /// Numéro de suivi d'un colis ou d'une de ses pièces ; renvoie l'identifiant du colis.
  Future<String> rechercher(String numero) => appelApi(() async {
        final res = await dio.get(Env.personnelColisRecherche(numero.trim()));
        return (res.data['data']['colis'] as Map<String, dynamic>)['id'] as String;
      }, tr('Aucune expédition ne correspond à ce numéro'));

  Future<String> enregistrerEvenement(
    String colisId,
    String code, {
    String? commentaire,
    String? motif,
    String? codeRetrait,
  }) =>
      appelApi(() async {
        final res = await dio.post(Env.personnelColisEvenement(colisId), data: {
          'codeEvenement': code,
          if (commentaire != null && commentaire.trim().isNotEmpty) 'commentaire': commentaire.trim(),
          if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
          if (codeRetrait != null && codeRetrait.trim().isNotEmpty) 'codeRetrait': codeRetrait.trim(),
        });
        return messageApi(res, tr('Suivi mis à jour.'));
      }, tr('Impossible d\'enregistrer l\'événement'));

  /// Règlement reçu en main propre ; le backend rattache l'agent à son point.
  Future<String> encaisser(String factureId, {required String methode, required double montant, String? reference}) =>
      appelApi(() async {
        final res = await dio.post(Env.personnelEncaissement(factureId), data: {
          'methode': methode,
          'montant': montant,
          if (reference != null && reference.trim().isNotEmpty) 'referenceTransaction': reference.trim(),
        });
        return messageApi(res, tr('Paiement enregistré.'));
      }, tr('Impossible d\'enregistrer le paiement'));
}
