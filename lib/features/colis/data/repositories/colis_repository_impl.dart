import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/demande_expedition.dart';
import '../../domain/repositories/colis_repository.dart';
import '../datasources/colis_remote_datasource.dart';
import '../../../../core/types/avec_message.dart';

class ColisRepositoryImpl implements ColisRepository {
  final ColisRemoteDataSource remote;
  ColisRepositoryImpl(this.remote);

  Future<Either<Failure, T>> _executer<T>(Future<T> Function() appel) async {
    try {
      return Right(await appel());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColis({String? statut, int page = 1, int limit = 20}) =>
      _executer(() => remote.getColis(statut: statut, page: page, limit: limit));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColisRecus({String? statut, int page = 1, int limit = 20}) =>
      _executer(() => remote.getColisRecus(statut: statut, page: page, limit: limit));

  @override
  Future<Either<Failure, Colis>> getColisDetail(String id) => _executer(() => remote.getColisDetail(id));

  @override
  Future<Either<Failure, ResultatDeclaration>> creerColis(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) =>
      _executer(() => remote.creerColis(demande, photosPaths: photosPaths, onSendProgress: onSendProgress));

  @override
  Future<Either<Failure, List<SuiviEvenement>>> getSuiviColis(String id) =>
      _executer(() => remote.getSuiviColis(id));

  @override
  Future<Either<Failure, AvecMessage<Colis>>> annulerColis(String id, {String? motif}) =>
      _executer(() => remote.annulerColis(id, motif: motif));

  @override
  Future<Either<Failure, ResultatDeclaration>> accepterProposition(String id) =>
      _executer(() => remote.accepterProposition(id));

  @override
  Future<Either<Failure, AvecMessage<Colis>>> refuserProposition(String id, {String? motif}) =>
      _executer(() => remote.refuserProposition(id, motif: motif));

  @override
  Future<Either<Failure, AvecMessage<Colis>>> modifierColis(String id, Map<String, dynamic> champs) =>
      _executer(() => remote.modifierColis(id, champs));
}
