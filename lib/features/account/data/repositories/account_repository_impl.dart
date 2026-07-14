import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/account_user.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  AccountRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AccountUser>> getMe() async {
    try { return Right(await remoteDataSource.getMe()); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, AccountUser>> modifierInfoPersonnelles({String? nom, String? prenom, String? telephone}) async {
    try { return Right(await remoteDataSource.modifierInfo(nom: nom, prenom: prenom, telephone: telephone)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, AccountUser>> uploadAvatar(String filePath) async {
    try { return Right(await remoteDataSource.uploadAvatar(filePath)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> changePassword({required String oldPassword, required String newPassword}) async {
    try { await remoteDataSource.changePassword(oldPassword, newPassword); return const Right(null); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }
}
