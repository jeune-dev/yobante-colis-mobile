import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/ville_model.dart';

abstract class VillesRemoteDataSource {
  Future<List<VilleModel>> getVilles();
}

class VillesRemoteDataSourceImpl implements VillesRemoteDataSource {
  final Dio dio;
  VillesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<VilleModel>> getVilles() async {
    try {
      final res = await dio.get(Env.adminVilles, queryParameters: {'isActive': true, 'limit': 200});
      final data = res.data['data'];
      final list = (data is List ? data : data['villes'] as List);
      return list.map((e) => VilleModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }
}
