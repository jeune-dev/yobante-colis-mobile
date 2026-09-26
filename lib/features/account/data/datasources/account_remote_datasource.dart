import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../models/account_user_model.dart';
import '../../../../core/i18n/langue.dart';

abstract class AccountRemoteDataSource {
  Future<AccountUserModel> getMe();
  Future<AccountUserModel> modifierInfo({String? nom, String? prenom, String? telephone});
  Future<AccountUserModel> uploadAvatar(String filePath);
  Future<void> changePassword(String oldPassword, String newPassword);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final Dio dio;
  AccountRemoteDataSourceImpl({required this.dio});

  @override
  Future<AccountUserModel> getMe() async {
    try {
      final res = await dio.get(Env.clientProfil);
      return AccountUserModel.fromJson(res.data['data']['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }

  @override
  Future<AccountUserModel> modifierInfo({String? nom, String? prenom, String? telephone}) async {
    try {
      final data = <String, dynamic>{};
      if (nom != null) data['nom'] = nom;
      if (prenom != null) data['prenom'] = prenom;
      if (telephone != null) data['telephone'] = normaliserTelephone(telephone);
      final res = await dio.put(Env.clientProfil, data: data);
      return AccountUserModel.fromJson(res.data['data']['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }

  @override
  Future<AccountUserModel> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(filePath)});
      final res = await dio.post(Env.clientProfilAvatar, data: formData);
      return AccountUserModel.fromJson(res.data['data']['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await dio.put(Env.authChangePass, data: {'oldPassword': oldPassword, 'newPassword': newPassword});
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur')));
    }
  }
}
