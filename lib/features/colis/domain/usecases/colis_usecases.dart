import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class GetColis {
  final ColisRepository repo;
  GetColis(this.repo);
  Future<Either<Failure, Map<String, dynamic>>> call({String? statut, int page = 1, int limit = 20}) =>
      repo.getColis(statut: statut, page: page, limit: limit);
}

class GetColisDetail {
  final ColisRepository repo;
  GetColisDetail(this.repo);
  Future<Either<Failure, Colis>> call(String id) => repo.getColisDetail(id);
}

class CreerColis {
  final ColisRepository repo;
  CreerColis(this.repo);
  Future<Either<Failure, Map<String, dynamic>>> call({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) =>
      repo.creerColis(
        expediteurNom: expediteurNom,
        expediteurTelephone: expediteurTelephone,
        villeDepartId: villeDepartId,
        destinataireNom: destinataireNom,
        destinataireTelephone: destinataireTelephone,
        villeArriveeId: villeArriveeId,
        adresseLivraison: adresseLivraison,
        poids: poids,
        description: description,
        typeColis: typeColis,
        valeurDeclaree: valeurDeclaree,
        photosPaths: photosPaths,
        onSendProgress: onSendProgress,
      );
}

class GetSuiviColis {
  final ColisRepository repo;
  GetSuiviColis(this.repo);
  Future<Either<Failure, List<SuiviColis>>> call(String id) => repo.getSuiviColis(id);
}

class AnnulerColis {
  final ColisRepository repo;
  AnnulerColis(this.repo);
  Future<Either<Failure, Colis>> call(String id, {String? motif}) =>
      repo.annulerColis(id, motif: motif);
}
