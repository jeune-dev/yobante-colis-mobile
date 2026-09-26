import 'package:dio/dio.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/categories.dart';
import '../../../core/errors/api_error.dart';
import '../domain/catalogue_entities.dart';
import '../../../core/i18n/langue.dart';

/// Accès aux points publics du backend (sans authentification, sauf le devis
/// d'un client connecté qui bénéficie alors de ses remises).
class CatalogueRemoteDataSource {
  final Dio dio;
  CatalogueRemoteDataSource({required this.dio});

  ConfigurationPublique? _configuration;

  Map<String, dynamic> _data(Response res) => res.data['data'] as Map<String, dynamic>;

  /// Configuration publique, mise en cache pour la durée de la session.
  Future<ConfigurationPublique> getConfiguration({bool forcer = false}) async {
    if (_configuration != null && !forcer) return _configuration!;
    return appelApi(() async {
      final res = await dio.get(Env.publicConfiguration);
      return _configuration =
          ConfigurationPublique.fromJson(_data(res)['configuration'] as Map<String, dynamic>);
    });
  }

  /// Règles des catégories de colis (photos minimales, modes de dépôt, paiement…),
  /// appliquées aux constantes de l'application.
  Future<void> chargerCategories() => appelApi(() async {
        final res = await dio.get(Env.publicCategories);
        CategorieColis.appliquerRegles(_data(res)['categories'] as List? ?? const []);
      });

  Future<ContenuAccueil> getAccueil({String? codePostal}) => appelApi(() async {
        final res = await dio.get(Env.publicAccueil, queryParameters: {
          if (codePostal != null && codePostal.isNotEmpty) 'codePostal': codePostal,
        });
        final d = _data(res);
        return ContenuAccueil(
          annonces: (d['annonces'] as List? ?? [])
              .map((a) => Annonce.fromJson(a as Map<String, dynamic>))
              .toList(),
          tournees: (d['tourneesCollecte'] as List? ?? [])
              .map((t) => TourneeCollecte.fromJson(t as Map<String, dynamic>))
              .toList(),
        );
      });

  Future<List<TourneeCollecte>> getTournees({String? pays, String? codePostal, String? villeId}) =>
      appelApi(() async {
        final res = await dio.get(Env.publicTournees, queryParameters: {
          'pays': ?pays,
          if (codePostal != null && codePostal.isNotEmpty) 'codePostal': codePostal,
          'villeId': ?villeId,
        });
        return (_data(res)['tournees'] as List? ?? [])
            .map((t) => TourneeCollecte.fromJson(t as Map<String, dynamic>))
            .toList();
      });

  Future<List<ArticleTarif>> getTarifs({String? categorie, String? modeTransport, String? paysDepart}) =>
      appelApi(() async {
        final res = await dio.get(Env.publicTarifs, queryParameters: {
          'categorie': ?categorie,
          'modeTransport': ?modeTransport,
          'paysDepart': ?paysDepart,
        });
        return (_data(res)['articles'] as List? ?? [])
            .map((a) => ArticleTarif.fromJson(a as Map<String, dynamic>))
            .toList();
      });

  Future<List<Emballage>> getEmballages({String? categorie}) => appelApi(() async {
        final res = await dio.get(Env.publicEmballages, queryParameters: {
          'categorie': ?categorie,
        });
        return (_data(res)['emballages'] as List? ?? [])
            .map((e) => Emballage.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<List<ServiceExpedition>> getServices() => appelApi(() async {
        final res = await dio.get(Env.publicServices);
        return (_data(res)['services'] as List? ?? [])
            .map((s) => ServiceExpedition.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  Future<List<VilleDesservie>> getVilles({String? pays}) => appelApi(() async {
        final res = await dio.get(Env.publicVilles, queryParameters: {'pays': ?pays});
        return (_data(res)['villes'] as List? ?? [])
            .map((v) => VilleDesservie.fromJson(v as Map<String, dynamic>))
            .toList();
      });

  Future<List<PointService>> getPoints({String? villeId, String? pays, String? service}) =>
      appelApi(() async {
        final res = await dio.get(Env.publicPointsCollecte, queryParameters: {
          'villeId': ?villeId,
          'pays': ?pays,
          'service': ?service,
        });
        return (_data(res)['points'] as List? ?? [])
            .map((p) => PointService.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  /// Compare les offres pour un besoin d'expédition. Connecté, le devis intègre
  /// les remises (professionnel, parrainage) et le crédit du compte.
  Future<ResultatDevis> devis(Map<String, dynamic> besoin, {bool connecte = false}) =>
      appelApi(() async {
        final res = await dio.post(
          connecte ? Env.clientDevis : Env.publicDevis,
          data: besoin,
          options: connecte ? null : Options(extra: {'skipAuthInterceptor': true}),
        );
        return ResultatDevis.fromJson(_data(res)['devis'] as Map<String, dynamic>);
      }, tr('Impossible de calculer le tarif'));
}
