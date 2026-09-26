import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/facture_colis_model.dart';
import '../../domain/entities/reglement.dart';
import '../../../../core/i18n/langue.dart';

abstract class PaiementsRemoteDataSource {
  Future<List<FactureColisModel>> getFactures();
  Future<FactureColisModel> getFactureDetail(String id);

  /// Historique des règlements du client.
  Future<List<Reglement>> getReglements({int page = 1, int limit = 50});

  /// Sommes dues, par devise.
  Future<Encours> getEncours();

  /// Moyens de paiement acceptés, par pays de règlement (`FR`, `SN`).
  Future<Map<String, List<String>>> getMethodes();
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
      throw ServerException(message: messageErreur(e, tr('Erreur lors du chargement des factures')));
    }
  }

  @override
  Future<FactureColisModel> getFactureDetail(String id) async {
    try {
      final res = await dio.get(Env.clientFactureId(id));
      return FactureColisModel.fromJson(res.data['data']['facture'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: messageErreur(e, tr('Erreur lors du chargement de la facture')));
    }
  }

  @override
  Future<List<Reglement>> getReglements({int page = 1, int limit = 50}) => appelApi(() async {
        final res = await dio.get(Env.clientPaiements, queryParameters: {'page': page, 'limit': limit});
        return (res.data['data']['paiements'] as List? ?? [])
            .map((p) => Reglement.fromJson(p as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger vos règlements'));

  @override
  Future<Encours> getEncours() => appelApi(() async {
        final res = await dio.get(Env.clientPaiementsEncours);
        return Encours.fromJson(res.data['data']['encours'] as Map<String, dynamic>? ?? {});
      }, tr('Impossible de charger votre encours'));

  @override
  Future<Map<String, List<String>>> getMethodes() => appelApi(() async {
        final res = await dio.get(Env.clientPaiementsMethodes);
        final brut = res.data['data']['methodes'];
        if (brut is Map) {
          return brut.map((k, v) => MapEntry('$k', (v as List? ?? []).map((m) => '$m').toList()));
        }
        return <String, List<String>>{};
      }, tr('Impossible de charger les moyens de paiement'));
}
