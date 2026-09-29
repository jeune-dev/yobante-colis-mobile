import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/account_user.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';
import '../../../../core/types/avec_message.dart';

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
  Future<Either<Failure, AvecMessage<AccountUser>>> modifierInfoPersonnelles({String? nom, String? prenom, String? telephone}) async {
    try { return Right(await remoteDataSource.modifierInfo(nom: nom, prenom: prenom, telephone: telephone)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, AvecMessage<AccountUser>>> uploadAvatar(String filePath) async {
    try { return Right(await remoteDataSource.uploadAvatar(filePath)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, String>> changePassword({required String oldPassword, required String newPassword}) async {
    try { return Right(await remoteDataSource.changePassword(oldPassword, newPassword)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }
}
