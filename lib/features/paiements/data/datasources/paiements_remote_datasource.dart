import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/facture_colis_model.dart';

abstract class PaiementsRemoteDataSource {
  Future<List<FactureColisModel>> getFactures();
  Future<FactureColisModel> getFactureDetail(String id);
}

class PaiementsRemoteDataSourceImpl implements PaiementsRemoteDataSource {
  final Dio dio;
  PaiementsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<FactureColisModel>> getFactures() async {
    try {
      final res = await dio.get(Env.clientFactures);
      final list = res.data['data']['factures'] as List? ?? [];
      return list.map((e) => FactureColisModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? 'Erreur chargement factures');
    }
  }

  @override
  Future<FactureColisModel> getFactureDetail(String id) async {
    try {
      final res = await dio.get(Env.clientFactureId(id));
      return FactureColisModel.fromJson(res.data['data']['facture'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? 'Erreur chargement facture');
    }
  }
}
