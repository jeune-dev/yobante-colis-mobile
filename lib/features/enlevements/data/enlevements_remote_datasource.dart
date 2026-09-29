import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';

/// Demandes d'enlèvement à domicile du client (`/client/enlevements`).

Map<String, String> get kStatutsEnlevement => {
  'demande': tr('Demande reçue'),
  'planifie': tr('Planifié'),
  'en_cours': tr('Coursier en route'),
  'effectue': tr('Effectué'),
  'echoue': tr('Échoué'),
  'annule': tr('Annulé'),
};

const List<String> kCreneauxEnlevement = ['08:00-12:00', '12:00-16:00', '16:00-20:00'];

double? _dn(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

class DemandeEnlevement extends Equatable {
  final String id;
  final String reference;
  final String? colisId;
  final String? colisReference;
  final String contactNom;
  final String contactTelephone;
  final String pays;
  final String villeId;
  final String? villeNom;
  final String adresse;
  final String? complementAdresse;
  final String? codePostal;
  final String dateSouhaitee;
  final String creneau;
  final String? heureSouhaitee;
  final int? etage;
  final bool? ascenseur;
  final bool emballageRequis;
  final int nbColis;
  final double? poidsEstimeKg;
  final String? instructions;
  final String statut;
  final String? datePlanifiee;
  final String? motifEchec;
  final double? fraisEnlevement;
  final String? tourneeTitre;
  final DateTime createdAt;

  const DemandeEnlevement({
    required this.id,
    required this.reference,
    this.colisId,
    this.colisReference,
    required this.contactNom,
    required this.contactTelephone,
    required this.pays,
    required this.villeId,
    this.villeNom,
    required this.adresse,
    this.complementAdresse,
    this.codePostal,
    required this.dateSouhaitee,
    required this.creneau,
    this.heureSouhaitee,
    this.etage,
    this.ascenseur,
    this.emballageRequis = false,
    this.nbColis = 1,
    this.poidsEstimeKg,
    this.instructions,
    required this.statut,
    this.datePlanifiee,
    this.motifEchec,
    this.fraisEnlevement,
    this.tourneeTitre,
    required this.createdAt,
  });

  String get statutLibelle => kStatutsEnlevement[statut] ?? statut;

  /// Le backend n'accepte de modification que tant que la demande n'est pas prise en charge.
  bool get modifiable => statut == 'demande';

  /// Annulable tant que le coursier n'est pas en route et que la demande n'est pas close.
  bool get annulable => !const ['en_cours', 'effectue', 'annule'].contains(statut);

  factory DemandeEnlevement.fromJson(Map<String, dynamic> j) => DemandeEnlevement(
        id: j['id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        colisId: j['colisId'] as String?,
        colisReference: (j['colis'] as Map<String, dynamic>?)?['reference'] as String?,
        contactNom: j['contactNom'] as String? ?? '',
        contactTelephone: j['contactTelephone'] as String? ?? '',
        pays: j['pays'] as String? ?? 'FR',
        villeId: j['villeId'] as String? ?? '',
        villeNom: (j['ville'] as Map<String, dynamic>?)?['nom'] as String?,
        adresse: j['adresse'] as String? ?? '',
        complementAdresse: j['complementAdresse'] as String?,
        codePostal: j['codePostal'] as String?,
        dateSouhaitee: j['dateSouhaitee'] as String? ?? '',
        creneau: j['creneau'] as String? ?? kCreneauxEnlevement.first,
        heureSouhaitee: j['heureSouhaitee'] as String?,
        etage: (j['etage'] as num?)?.toInt(),
        ascenseur: j['ascenseur'] as bool?,
        emballageRequis: j['emballageRequis'] as bool? ?? false,
        nbColis: (j['nbColis'] as num?)?.toInt() ?? 1,
        poidsEstimeKg: _dn(j['poidsEstimeKg']),
        instructions: j['instructions'] as String?,
        statut: j['statut'] as String? ?? 'demande',
        datePlanifiee: j['datePlanifiee'] as String?,
        motifEchec: j['motifEchec'] as String?,
        fraisEnlevement: _dn(j['fraisEnlevement']),
        tourneeTitre: (j['tourneeCollecte'] as Map<String, dynamic>?)?['titre'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, statut, dateSouhaitee, creneau];
}

/// Créneaux proposés et prochaines dates ouvrées.
class CreneauxEnlevement {
  final List<String> creneaux;
  final List<String> dates;
  const CreneauxEnlevement({this.creneaux = kCreneauxEnlevement, this.dates = const []});
}

class EnlevementsRemoteDataSource {
  final Dio dio;
  EnlevementsRemoteDataSource({required this.dio});

  DemandeEnlevement _demande(Response res) =>
      DemandeEnlevement.fromJson(res.data['data']['demande'] as Map<String, dynamic>);

  Future<CreneauxEnlevement> getCreneaux() => appelApi(() async {
        final res = await dio.get(Env.clientEnlevementsCreneaux);
        final d = res.data['data'] as Map<String, dynamic>;
        return CreneauxEnlevement(
          creneaux: (d['creneaux'] as List? ?? kCreneauxEnlevement).map((c) => '$c').toList(),
          dates: (d['dates'] as List? ?? const []).map((c) => '$c').toList(),
        );
      }, tr('Impossible de charger les créneaux'));

  Future<List<DemandeEnlevement>> getDemandes({bool? enCours}) => appelApi(() async {
        final res = await dio.get(Env.clientEnlevements, queryParameters: {
          'limit': 100,
          if (enCours != null) 'enCours': '$enCours',
        });
        return (res.data['data']['demandes'] as List? ?? [])
            .map((d) => DemandeEnlevement.fromJson(d as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger vos enlèvements'));

  Future<DemandeEnlevement> getDemande(String id) =>
      appelApi(() async => _demande(await dio.get(Env.clientEnlevementId(id))), tr('Demande introuvable'));

  /// Champs : colisId, contactNom, contactTelephone, pays, villeId, adresse,
  /// complementAdresse, codePostal, dateSouhaitee, creneau, nbColis,
  /// poidsEstimeKg, instructions, tourneeCollecteId, heureSouhaitee, etage,
  /// ascenseur, emballageRequis. Renvoie la demande et le message du backend.
  Future<({DemandeEnlevement demande, String message})> creer(Map<String, dynamic> champs) => appelApi(() async {
        final res = await dio.post(Env.clientEnlevements, data: champs);
        return (demande: _demande(res), message: messageApi(res));
      }, tr('Impossible de programmer l\'enlèvement'));

  Future<({DemandeEnlevement demande, String message})> modifier(String id, Map<String, dynamic> champs) =>
      appelApi(() async {
        final res = await dio.put(Env.clientEnlevementId(id), data: champs);
        return (demande: _demande(res), message: messageApi(res));
      }, tr('Impossible de modifier la demande'));

  Future<({DemandeEnlevement demande, String message})> annuler(String id, {String? motif}) => appelApi(() async {
        final res = await dio.patch(Env.clientEnlevementAnnuler(id), data: {
          if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
        });
        return (demande: _demande(res), message: messageApi(res));
      }, tr('Impossible d\'annuler la demande'));
}
