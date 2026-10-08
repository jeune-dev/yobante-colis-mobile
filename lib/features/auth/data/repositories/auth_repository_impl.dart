import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenService tokenService;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({required this.remoteDataSource, required this.tokenService, required this.secureStorage});

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      return Right(await _ouvrirSession(await remoteDataSource.login(email, password)));
    } on EmailNonConfirmeException catch (e) {
      return Left(EmailNonConfirmeFailure(e.message, email: e.email));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Enregistre les jetons et l'identité du compte (connexion ou confirmation d'email).
  Future<User> _ouvrirSession(AuthResponseModel res) async {
    await tokenService.setToken(res.accessToken);
    if (res.refreshToken != null) await tokenService.setRefreshToken(res.refreshToken);
    await secureStorage.write(key: 'user_id', value: res.user.id);
    await secureStorage.write(key: 'user_role', value: res.user.role);
    return res.user;
  }

  @override
  Future<Either<Failure, User>> verifierEmail(String email, String code) async {
    try {
      return Right(await _ouvrirSession(await remoteDataSource.verifierEmail(email, code)));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> renvoyerCodeVerification(String email) async {
    try {
      return Right(await remoteDataSource.renvoyerCodeVerification(email));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
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
      final message = await remoteDataSource.register(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        telephone: telephone,
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
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    try {
      return Right(await remoteDataSource.forgotPassword(email));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword(String email, String code, String newPassword) async {
    try {
      return Right(await remoteDataSource.resetPassword(email, code, newPassword));
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
    // Révocation côté serveur au mieux : une erreur réseau ne doit pas laisser
    // l'utilisateur connecté sur le téléphone.
    if ((rt != null && rt.isNotEmpty) || (at != null && at.isNotEmpty)) {
      try {
        await remoteDataSource.logout(rt ?? '', accessToken: at);
      } catch (_) {}
    }
    await FcmService.oublierToken();
    await tokenService.clearToken();
    await secureStorage.delete(key: 'user_id');
    await secureStorage.delete(key: 'user_role');
  }
}
