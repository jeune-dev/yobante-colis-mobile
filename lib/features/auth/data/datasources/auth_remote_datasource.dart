import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../../core/i18n/langue.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);

  /// Inscription, mot de passe oublié, réinitialisation : renvoient le message du backend.
  Future<String> register({
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
  });
  Future<String> forgotPassword(String email);
  Future<String> resetPassword(String email, String code, String newPassword);
  Future<void> logout(String refreshToken, {String? accessToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final res = await dio.post(
        Env.authLogin,
        // Le backend accepte un email ou un numéro de téléphone dans « identifiant »
        data: {'identifiant': email, 'password': password},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      final model = AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
      return model;
    } on DioException catch (e) {
      final message = messageErreur(e, tr('Erreur de connexion'));
      // 403 à la connexion : compte désactivé, ou email pas encore confirmé
      final nonConfirme =
          codeErreur(e) == 'EMAIL_NON_CONFIRME' ||
          (e.response?.statusCode == 403 && message.toLowerCase().contains('confirm'));
      if (nonConfirme) {
        throw EmailNonConfirmeException(message: message);
      }
      throw ServerException(message: message);
    }
  }

  @override
  Future<String> register({
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
      final res = await dio.post(
        Env.authRegister,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password': motDePasse,
          'telephone': telephone,
          'pays': pays,
          'villeId': ?villeId,
          if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
          'typeCompte': typeCompte,
          if (raisonSociale != null && raisonSociale.isNotEmpty) 'raisonSociale': raisonSociale,
          if (numeroIdentificationFiscale != null && numeroIdentificationFiscale.isNotEmpty)
            'numeroIdentificationFiscale': numeroIdentificationFiscale,
          if (numeroTvaIntracom != null && numeroTvaIntracom.isNotEmpty) 'numeroTvaIntracom': numeroTvaIntracom,
          if (codePostal != null && codePostal.isNotEmpty) 'codePostal': codePostal,
          if (codeParrainage != null && codeParrainage.isNotEmpty) 'codeParrainage': codeParrainage,
        },
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      return messageApi(res);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur d\'inscription')));
    }
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      return messageApi(
        await dio.post(
          Env.authForgot,
          data: {'email': email},
          options: Options(extra: {'skipAuthInterceptor': true}),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }

  @override
  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      return messageApi(
        await dio.post(
          Env.authReset,
          data: {'email': email, 'code': code, 'newPassword': newPassword},
          options: Options(extra: {'skipAuthInterceptor': true}),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }

  @override
  Future<void> logout(String refreshToken, {String? accessToken}) async {
    try {
      // Le jeton d'accès (même expiré) est joint pour être révoqué immédiatement
      await dio.post(
        Env.authLogout,
        // Seul « refreshToken » est accepté par le backend. Les push de ce téléphone
        // sont coupés côté Firebase (FcmService.oublierToken) : le jeton n'existe plus.
        data: {if (refreshToken.isNotEmpty) 'refreshToken': refreshToken},
        options: Options(
          extra: {'skipAuthInterceptor': true},
          headers: {if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on DioException {
      // Best-effort — ne pas bloquer la déconnexion locale si le backend est down
    }
  }
}
