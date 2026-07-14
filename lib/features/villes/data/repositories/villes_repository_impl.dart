import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/ville.dart';
import '../../domain/repositories/villes_repository.dart';
import '../datasources/villes_remote_datasource.dart';

class VillesRepositoryImpl implements VillesRepository {
  final VillesRemoteDataSource remote;
  VillesRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Ville>>> getVilles() async {
    try {
      return Right(await remote.getVilles());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
