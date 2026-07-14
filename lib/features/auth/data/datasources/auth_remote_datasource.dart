import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<void> register({
    required String nom, required String prenom,
    required String email, required String motDePasse, required String telephone,
  });
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String code, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final res = await dio.post(
        Env.authLogin,
        data: {'email': email, 'password': password},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      final model = AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
      return model;
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur de connexion');
    }
  }

  @override
  Future<void> register({
    required String nom, required String prenom,
    required String email, required String motDePasse, required String telephone,
  }) async {
    try {
      await dio.post(
        Env.authRegister,
        data: {'nom': nom, 'prenom': prenom, 'email': email, 'password': motDePasse, 'telephone': telephone},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur d\'inscription');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(Env.authForgot, data: {'email': email},
          options: Options(extra: {'skipAuthInterceptor': true}));
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? 'Erreur');
    }
  }

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      await dio.post(Env.authReset, data: {'email': email, 'code': code, 'newPassword': newPassword},
          options: Options(extra: {'skipAuthInterceptor': true}));
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? 'Erreur');
    }
  }
}
