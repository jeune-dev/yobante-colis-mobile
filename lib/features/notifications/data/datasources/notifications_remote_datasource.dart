import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20});
  Future<int> getNonLuesCount();
  Future<void> marquerLue(String id);
  Future<void> marquerToutesLues();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio dio;
  NotificationsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final res = await dio.get(Env.clientNotifications, queryParameters: {'page': page, 'limit': limit});
      final list = res.data['data']['notifications'] as List;
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur');
    }
  }

  @override
  Future<int> getNonLuesCount() async {
    try {
      final res = await dio.get(Env.clientNotifNonLues);
      return res.data['data']['total'] as int? ?? 0;
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur');
    }
  }

  @override
  Future<void> marquerLue(String id) async {
    try {
      await dio.patch(Env.clientNotifLue(id));
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur');
    }
  }

  @override
  Future<void> marquerToutesLues() async {
    try {
      await dio.patch(Env.clientNotifToutesLues);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur');
    }
  }
}
