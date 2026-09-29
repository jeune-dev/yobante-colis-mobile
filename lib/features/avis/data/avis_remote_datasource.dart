import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';

/// Avis clients : avis publiés (`GET /public/avis`) et avis du client connecté
/// (`/client/avis`), publiés après modération.

Map<String, String> get kStatutsAvis => {
  'en_attente': tr('En attente de vérification'),
  'publie': tr('Publié'),
  'rejete': tr('Non publié'),
};

class Avis extends Equatable {
  final String id;
  final int note;
  final String? titre;
  final String? commentaire;
  final String? reponse;
  final String? auteur;
  final String? statut;
  final String? motifRejet;
  final String? colisId;
  final String? colisReference;
  final DateTime date;

  const Avis({
    required this.id,
    required this.note,
    this.titre,
    this.commentaire,
    this.reponse,
    this.auteur,
    this.statut,
    this.motifRejet,
    this.colisId,
    this.colisReference,
    required this.date,
  });

  factory Avis.fromJson(Map<String, dynamic> j) => Avis(
        id: j['id'] as String? ?? '',
        note: (j['note'] as num?)?.toInt() ?? 0,
        titre: j['titre'] as String?,
        commentaire: j['commentaire'] as String?,
        reponse: j['reponse'] as String?,
        auteur: j['auteur'] as String?,
        statut: j['statut'] as String?,
        motifRejet: j['motifRejet'] as String?,
        colisId: j['colisId'] as String?,
        colisReference: (j['colis'] as Map<String, dynamic>?)?['reference'] as String?,
        date: DateTime.tryParse((j['date'] ?? j['createdAt'] ?? '') as String) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, statut];
}

class SyntheseAvis {
  final int total;
  final double noteMoyenne;
  final Map<int, int> repartition;
  const SyntheseAvis({this.total = 0, this.noteMoyenne = 0, this.repartition = const {}});

  factory SyntheseAvis.fromJson(Map<String, dynamic>? j) => SyntheseAvis(
        total: (j?['total'] as num?)?.toInt() ?? 0,
        noteMoyenne: (j?['noteMoyenne'] as num?)?.toDouble() ?? 0,
        repartition: {
          for (final r in (j?['repartition'] as List? ?? const []))
            ((r as Map)['note'] as num).toInt(): (r['total'] as num?)?.toInt() ?? 0,
        },
      );
}

class AvisRemoteDataSource {
  final Dio dio;
  AvisRemoteDataSource({required this.dio});

  Future<({SyntheseAvis synthese, List<Avis> avis, int totalPages})> getAvisPublics({int page = 1, int? note}) =>
      appelApi(() async {
        final res = await dio.get(Env.publicAvis,
            queryParameters: {'page': page, 'limit': 20, 'note': ?note},
            options: Options(extra: {'skipAuthInterceptor': true}));
        final d = res.data['data'] as Map<String, dynamic>;
        return (
          synthese: SyntheseAvis.fromJson(d['synthese'] as Map<String, dynamic>?),
          avis: (d['avis'] as List? ?? []).map((a) => Avis.fromJson(a as Map<String, dynamic>)).toList(),
          totalPages: ((d['pagination'] as Map?)?['totalPages'] as num?)?.toInt() ?? 1,
        );
      }, tr('Impossible de charger les avis'));

  Future<List<Avis>> getMesAvis() => appelApi(() async {
        final res = await dio.get(Env.clientAvis);
        return (res.data['data']['avis'] as List? ?? [])
            .map((a) => Avis.fromJson(a as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger vos avis'));

  /// Dépose un avis (un seul par expédition). Renvoie le message du backend.
  Future<String> deposer({required int note, String? titre, String? commentaire, String? colisId}) =>
      appelApi(() async {
        final res = await dio.post(Env.clientAvis, data: {
          'note': note,
          if (titre != null && titre.trim().isNotEmpty) 'titre': titre.trim(),
          if (commentaire != null && commentaire.trim().isNotEmpty) 'commentaire': commentaire.trim(),
          'colisId': ?colisId,
        });
        return messageApi(res);
      }, tr('Impossible d\'enregistrer votre avis'));

  /// Renvoie le message du backend.
  Future<String> supprimer(String id) => appelApi(
      () async => messageApi(await dio.delete(Env.clientAvisId(id))), tr('Impossible de supprimer l\'avis'));
}
