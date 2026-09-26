import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenService tokenService;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenService,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final res = await remoteDataSource.login(email, password);
      await tokenService.setToken(res.accessToken);
      if (res.refreshToken != null) await tokenService.setRefreshToken(res.refreshToken);
      await secureStorage.write(key: 'user_id', value: res.user.id);
      await secureStorage.write(key: 'user_role', value: res.user.role);
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
    String pays = 'SN',
    String? villeId,
    String? adresse,
    String typeCompte = 'particulier',
    String? raisonSociale,
    String? numeroIdentificationFiscale,
    String? numeroTvaIntracom,
    String? codePostal,
    String? codeParrainage,
  }) async {
    try {
      await remoteDataSource.register(
        nom: nom, prenom: prenom, email: email, motDePasse: motDePasse, telephone: telephone,
        pays: pays,
        villeId: villeId,
        adresse: adresse,
        typeCompte: typeCompte,
        raisonSociale: raisonSociale,
        numeroIdentificationFiscale: numeroIdentificationFiscale,
        numeroTvaIntracom: numeroTvaIntracom,
        codePostal: codePostal,
        codeParrainage: codeParrainage,
      );
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
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(email, code, newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    final rt = await tokenService.getRefreshToken();
    final at = await tokenService.getToken();
    if ((rt != null && rt.isNotEmpty) || (at != null && at.isNotEmpty)) {
      await remoteDataSource.logout(rt ?? '', accessToken: at);
    }
    await tokenService.clearToken();
    await secureStorage.delete(key: 'user_id');
    await secureStorage.delete(key: 'user_role');
  }
}
