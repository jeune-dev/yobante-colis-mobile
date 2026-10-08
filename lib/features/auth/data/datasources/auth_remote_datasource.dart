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

  /// Confirme l'adresse avec le code reçu par email : ouvre la session (jetons).
  Future<AuthResponseModel> verifierEmail(String email, String code);

  /// Redemande un code de confirmation (réponse identique que le compte existe ou non).
  Future<String> renvoyerCodeVerification(String email);
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
        final data = e.response?.data;
        final email = data is Map ? data['email'] : null;
        throw EmailNonConfirmeException(message: message, email: email is String ? email : null);
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
  Future<AuthResponseModel> verifierEmail(String email, String code) async {
    try {
      final res = await dio.post(
        Env.authVerifyEmail,
        data: {'email': email, 'code': code},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      return AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Code incorrect ou expiré')));
    }
  }

  @override
  Future<String> renvoyerCodeVerification(String email) async {
    try {
      return messageApi(
        await dio.post(
          Env.authResendVerification,
          data: {'email': email},
          options: Options(extra: {'skipAuthInterceptor': true}),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Envoi impossible pour le moment.')));
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
