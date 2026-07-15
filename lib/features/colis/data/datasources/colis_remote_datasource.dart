import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/colis_model.dart';

abstract class ColisRemoteDataSource {
  Future<Map<String, dynamic>> getColis({String? statut, int page = 1, int limit = 20});
  Future<ColisModel> getColisDetail(String id);
  Future<Map<String, dynamic>> creerColis({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  });
  Future<List<SuiviColisModel>> getSuiviColis(String id);
  Future<ColisModel> annulerColis(String id, {String? motif});
}

class ColisRemoteDataSourceImpl implements ColisRemoteDataSource {
  final Dio dio;
  ColisRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getColis({String? statut, int page = 1, int limit = 20}) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (statut != null) params['statut'] = statut;
      final res = await dio.get(Env.clientColis, queryParameters: params);
      final data = res.data['data'] as Map<String, dynamic>;
      final list = (data['colis'] as List).map((e) => ColisModel.fromJson(e as Map<String, dynamic>)).toList();
      return {'colis': list, 'pagination': data['pagination']};
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }

  @override
  Future<ColisModel> getColisDetail(String id) async {
    try {
      final res = await dio.get(Env.clientColisId(id));
      return ColisModel.fromJson(res.data['data']['colis'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }

  @override
  Future<Map<String, dynamic>> creerColis({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'expediteurNom': expediteurNom,
        'expediteurTelephone': expediteurTelephone,
        'villeDepartId': villeDepartId,
        'destinataireNom': destinataireNom,
        'destinataireTelephone': destinataireTelephone,
        'villeArriveeId': villeArriveeId,
        'adresseLivraison': adresseLivraison,
        'poids': poids.toString(),
        'typeColis': typeColis,
        'description': ?description,
        if (valeurDeclaree != null) 'valeurDeclaree': valeurDeclaree.toString(),
        if (photosPaths.isNotEmpty)
          'photos': photosPaths.map((p) => MultipartFile.fromFileSync(p)).toList(),
      });
      final res = await dio.post(
        Env.clientColis,
        data: formData,
        onSendProgress: onSendProgress,
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return {
        'colis': ColisModel.fromJson(data['colis'] as Map<String, dynamic>),
        'facture': data['facture'],
      };
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }

  @override
  Future<List<SuiviColisModel>> getSuiviColis(String id) async {
    try {
      final res = await dio.get(Env.clientColisSuivi(id));
      final list = res.data['data']['historique'] as List;
      return list.map((e) => SuiviColisModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }

  @override
  Future<ColisModel> annulerColis(String id, {String? motif}) async {
    try {
      final res = await dio.patch(Env.clientColisAnnuler(id), data: motif != null ? {'motif': motif} : {});
      return ColisModel.fromJson(res.data['data']['colis'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data?['message'] as String? ?? e.message ?? 'Erreur serveur');
    }
  }
}
