import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/facture_colis.dart';
import '../../domain/repositories/paiements_repository.dart';
import '../datasources/paiements_remote_datasource.dart';

class PaiementsRepositoryImpl implements PaiementsRepository {
  final PaiementsRemoteDataSource remoteDataSource;
  PaiementsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FactureColis>>> getFactures() async {
    try {
      return Right(await remoteDataSource.getFactures());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FactureColis>> getFactureDetail(String id) async {
    try {
      return Right(await remoteDataSource.getFactureDetail(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
