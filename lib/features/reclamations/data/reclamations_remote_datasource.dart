import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';

/// Service après-vente : réclamations du client connecté (perte, avarie,
/// retard…) instruites par le support à travers un fil de messages.

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// Motifs acceptés par le backend, avec leur libellé.
Map<String, String> get kTypesReclamation => {
  'perte': tr('Colis perdu'),
  'avarie': tr('Colis endommagé'),
  'retard': tr('Retard de livraison'),
  'erreur_livraison': tr('Erreur de livraison'),
  'facturation': tr('Facturation'),
  'douane': tr('Douane'),
  'autre': tr('Autre'),
};

Map<String, String> get kStatutsReclamation => {
  'ouverte': tr('Ouverte'),
  'en_cours': tr('En cours de traitement'),
  'attente_client': tr('En attente de votre réponse'),
  'resolue': tr('Résolue'),
  'rejetee': tr('Rejetée'),
  'cloturee': tr('Clôturée'),
};

class MessageReclamation extends Equatable {
  final String id;
  final String origine; // client | support
  final String message;
  final List<String> piecesJointes;
  final DateTime createdAt;

  const MessageReclamation({
    required this.id,
    required this.origine,
    required this.message,
    this.piecesJointes = const [],
    required this.createdAt,
  });

  bool get deClient => origine == 'client';

  factory MessageReclamation.fromJson(Map<String, dynamic> j) => MessageReclamation(
        id: j['id'] as String? ?? '',
        origine: j['origine'] as String? ?? 'support',
        message: j['message'] as String? ?? '',
        piecesJointes: (j['piecesJointes'] as List? ?? [])
            .map((p) => p is Map ? '${p['url']}' : '$p')
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

class Reclamation extends Equatable {
  final String id;
  final String reference;
  final String type;
  final String objet;
  final String description;
  final String statut;
  final String priorite;
  final double montantReclame;
  final double? montantAccorde;
  final String devise;
  final String? resolution;
  final String? motifRejet;
  final int? noteSatisfaction;
  final String? colisId;
  final String? colisReference;
  final List<String> piecesJointes;
  final List<MessageReclamation> messages;
  final DateTime createdAt;

  const Reclamation({
    required this.id,
    required this.reference,
    required this.type,
    required this.objet,
    required this.description,
    required this.statut,
    this.priorite = 'normale',
    this.montantReclame = 0,
    this.montantAccorde,
    this.devise = 'XOF',
    this.resolution,
    this.motifRejet,
    this.noteSatisfaction,
    this.colisId,
    this.colisReference,
    this.piecesJointes = const [],
    this.messages = const [],
    required this.createdAt,
  });

  /// Réclamation close : plus de réponse possible, la note devient disponible.
  bool get estClose => const ['resolue', 'rejetee', 'cloturee'].contains(statut);

  String get typeLibelle => kTypesReclamation[type] ?? type;
  String get statutLibelle => kStatutsReclamation[statut] ?? statut;

  factory Reclamation.fromJson(Map<String, dynamic> j) {
    final colis = j['colis'] as Map<String, dynamic>?;
    final accorde = j['montantAccorde'];
    return Reclamation(
      id: j['id'] as String? ?? '',
      reference: j['reference'] as String? ?? '',
      type: j['type'] as String? ?? 'autre',
      objet: j['objet'] as String? ?? '',
      description: j['description'] as String? ?? '',
      statut: j['statut'] as String? ?? 'ouverte',
      priorite: j['priorite'] as String? ?? 'normale',
      montantReclame: _d(j['montantReclame']),
      montantAccorde: accorde == null ? null : _d(accorde),
      devise: j['devise'] as String? ?? 'XOF',
      resolution: j['resolution'] as String?,
      motifRejet: j['motifRejet'] as String?,
      noteSatisfaction: (j['noteSatisfaction'] as num?)?.toInt(),
      colisId: j['colisId'] as String?,
      colisReference: colis?['reference'] as String?,
      piecesJointes: (j['piecesJointes'] as List? ?? [])
          .map((p) => p is Map ? '${p['url']}' : '$p')
          .toList(),
      messages: (j['messages'] as List? ?? [])
          .map((m) => MessageReclamation.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, statut, messages.length, noteSatisfaction];
}

class ReclamationsRemoteDataSource {
  final Dio dio;
  ReclamationsRemoteDataSource({required this.dio});

  Map<String, dynamic> _data(Response res) => res.data['data'] as Map<String, dynamic>;

  Future<List<Reclamation>> getReclamations({int page = 1, int limit = 50}) => appelApi(() async {
        final res = await dio.get(Env.clientReclamations, queryParameters: {'page': page, 'limit': limit});
        return (_data(res)['reclamations'] as List? ?? [])
            .map((r) => Reclamation.fromJson(r as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger vos réclamations'));

  Future<Reclamation> getReclamation(String id) => appelApi(() async {
        final res = await dio.get(Env.clientReclamationId(id));
        return Reclamation.fromJson(_data(res)['reclamation'] as Map<String, dynamic>);
      }, tr('Impossible de charger la réclamation'));

  /// Ouvre une réclamation (multipart : pièces jointes facultatives, champ « pieces »).
  Future<Reclamation> ouvrir({
    required String type,
    required String objet,
    required String description,
    String? colisId,
    double? montantReclame,
    String? devise,
    List<String> piecesPaths = const [],
  }) =>
      appelApi(() async {
        final form = FormData.fromMap({
          'type': type,
          'objet': objet.trim(),
          'description': description.trim(),
          'colisId': ?colisId,
          if (montantReclame != null && montantReclame > 0) 'montantReclame': '$montantReclame',
          'devise': ?devise,
        });
        for (final chemin in piecesPaths) {
          form.files.add(MapEntry('pieces', await MultipartFile.fromFile(chemin)));
        }
        final res = await dio.post(Env.clientReclamations, data: form);
        return Reclamation.fromJson(_data(res)['reclamation'] as Map<String, dynamic>);
      }, tr('Impossible d\'enregistrer la réclamation'));

  Future<void> repondre(String id, String message, {List<String> piecesPaths = const []}) =>
      appelApi(() async {
        final form = FormData.fromMap({'message': message.trim()});
        for (final chemin in piecesPaths) {
          form.files.add(MapEntry('pieces', await MultipartFile.fromFile(chemin)));
        }
        await dio.post(Env.clientReclamationMessages(id), data: form);
      }, tr('Envoi du message impossible'));

  /// Note de satisfaction (1 à 5), une fois la réclamation close.
  Future<void> noter(String id, int note) => appelApi(() async {
        await dio.patch(Env.clientReclamationNote(id), data: {'note': note});
      }, tr('Impossible d\'enregistrer la note'));
}
