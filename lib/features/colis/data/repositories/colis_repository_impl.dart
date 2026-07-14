import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/colis.dart';
import '../../domain/repositories/colis_repository.dart';
import '../datasources/colis_remote_datasource.dart';

class ColisRepositoryImpl implements ColisRepository {
  final ColisRemoteDataSource remote;
  ColisRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColis({String? statut, int page = 1, int limit = 20}) async {
    try {
      return Right(await remote.getColis(statut: statut, page: page, limit: limit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Colis>> getColisDetail(String id) async {
    try {
      return Right(await remote.getColisDetail(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> creerColis({
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
  }) async {
    try {
      return Right(await remote.creerColis(
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
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<SuiviColis>>> getSuiviColis(String id) async {
    try {
      return Right(await remote.getSuiviColis(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Colis>> annulerColis(String id, {String? motif}) async {
    try {
      return Right(await remote.annulerColis(id, motif: motif));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
