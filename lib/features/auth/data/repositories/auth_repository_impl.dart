import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final res = await remoteDataSource.login(email, password);
      await sl<TokenService>().setToken(res.accessToken);
      if (res.refreshToken != null) await sl<TokenService>().setRefreshToken(res.refreshToken);
      final storage = sl<FlutterSecureStorage>();
      await storage.write(key: 'user_id', value: res.user.id);
      await storage.write(key: 'user_role', value: res.user.role);
      return Right(res.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String nom, required String prenom,
    required String email, required String motDePasse, required String telephone,
  }) async {
    try {
      await remoteDataSource.register(nom: nom, prenom: prenom, email: email, motDePasse: motDePasse, telephone: telephone);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(email, code, newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
