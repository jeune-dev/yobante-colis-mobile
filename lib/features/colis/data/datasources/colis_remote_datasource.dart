import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../models/colis_model.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/demande_expedition.dart';
import '../../domain/entities/filtres_colis.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/fichier_upload.dart';
import '../../../../core/types/avec_message.dart';

abstract class ColisRemoteDataSource {
  Future<Map<String, dynamic>> getColis(
      {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20});
  Future<Map<String, dynamic>> getColisRecus(
      {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20});
  Future<ColisModel> getColisDetail(String id);

  /// Déclare une expédition (multipart : champs + photos du colis).
  Future<ResultatDeclaration> creerColis(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  });

  Future<List<SuiviEvenement>> getSuiviColis(String id);
  // Annulation, refus, modification : colis à jour et message du backend
  Future<AvecMessage<ColisModel>> annulerColis(String id, {String? motif});

  /// Catégorie 3 : réponse du client à la proposition tarifaire.
  Future<ResultatDeclaration> accepterProposition(String id);
  Future<AvecMessage<ColisModel>> refuserProposition(String id, {String? motif});

  /// Correction de la demande (destinataire, adresse) avant l'arrivée au Sénégal.
  Future<AvecMessage<ColisModel>> modifierColis(String id, Map<String, dynamic> champs);

  /// Photos complémentaires (10 au total par expédition). Renvoie le message du backend.
  Future<String> ajouterPhotos(String id, List<String> photosPaths);

  /// Dépose (ou remplace) le message vocal décrivant la demande (fichier m4a).
  Future<String> deposerVocal(String id, String cheminAudio);

  /// Inscrit une adresse email ou un numéro aux alertes de suivi.
  Future<String> abonnerSuivi(String id, {required String canal, required String destination, String profil = 'destinataire'});
}

class ColisRemoteDataSourceImpl implements ColisRemoteDataSource {
  final Dio dio;
  ColisRemoteDataSourceImpl({required this.dio});

  Map<String, dynamic> _parseListe(Map<String, dynamic> data) {
    final list = (data['colis'] as List)
        .map((e) => ColisModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'colis': list, 'pagination': data['pagination']};
  }

  Map<String, dynamic> _data(Response res) => res.data['data'] as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> getColis(
          {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20}) =>
      appelApi(() async {
        final params = <String, dynamic>{...filtres.versRequete(), 'page': page, 'limit': limit};
        if (statut != null) params['statut'] = statut;
        final res = await dio.get(Env.clientColis, queryParameters: params);
        return _parseListe(_data(res));
      }, tr('Erreur serveur'));

  @override
  Future<Map<String, dynamic>> getColisRecus(
          {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20}) =>
      appelApi(() async {
        final params = <String, dynamic>{...filtres.versRequete(recus: true), 'page': page, 'limit': limit};
        if (statut != null) params['statut'] = statut;
        final res = await dio.get(Env.clientColisRecus, queryParameters: params);
        return _parseListe(_data(res));
      }, tr('Erreur serveur'));

  @override
  Future<ColisModel> getColisDetail(String id) => appelApi(() async {
        final res = await dio.get(Env.clientColisId(id));
        return ColisModel.fromJson(_data(res)['colis'] as Map<String, dynamic>);
      }, tr('Erreur serveur'));

  @override
  Future<ResultatDeclaration> creerColis(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) =>
      appelApi(() async {
        final formData = FormData.fromMap(demande.versFormulaire());
        for (final chemin in photosPaths) {
          formData.files.add(MapEntry('photos', await fichierMultipart(chemin, tailleMax: kTailleMaxPhotoColis)));
        }
        final res = await dio.post(Env.clientColis, data: formData, onSendProgress: onSendProgress);
        final data = _data(res);
        final facture = data['facture'] as Map<String, dynamic>?;
        return ResultatDeclaration(
          colis: ColisModel.fromJson(data['colis'] as Map<String, dynamic>),
          message: messageApi(res),
          factureReference: facture?['reference'] as String?,
          lienPaiement: data['lienPaiement'] as String?,
          adresseReception: data['adresseReception'] as Map<String, dynamic>?,
        );
      }, tr('Erreur lors de l\'enregistrement de l\'expédition'));

  @override
  Future<List<SuiviEvenement>> getSuiviColis(String id) => appelApi(() async {
        final res = await dio.get(Env.clientColisSuivi(id));
        final list = _data(res)['historique'] as List;
        return list.map((e) => SuiviEvenement.fromJson(e as Map<String, dynamic>)).toList();
      }, tr('Erreur serveur'));

  @override
  Future<AvecMessage<ColisModel>> annulerColis(String id, {String? motif}) => appelApi(() async {
        final res = await dio.patch(Env.clientColisAnnuler(id), data: motif != null ? {'motif': motif} : {});
        return (valeur: ColisModel.fromJson(_data(res)['colis'] as Map<String, dynamic>), message: messageApi(res));
      }, tr('Erreur serveur'));

  @override
  Future<ResultatDeclaration> accepterProposition(String id) => appelApi(() async {
        final res = await dio.post(Env.clientColisAccepter(id));
        final data = _data(res);
        final facture = data['facture'] as Map<String, dynamic>?;
        return ResultatDeclaration(
          colis: ColisModel.fromJson(data['colis'] as Map<String, dynamic>),
          message: messageApi(res),
          factureReference: facture?['reference'] as String?,
          lienPaiement: data['lienPaiement'] as String?,
        );
      }, tr('Impossible d\'accepter la proposition'));

  @override
  Future<AvecMessage<ColisModel>> refuserProposition(String id, {String? motif}) => appelApi(() async {
        final res = await dio.post(Env.clientColisRefuser(id), data: {'motif': ?motif});
        return (valeur: ColisModel.fromJson(_data(res)['colis'] as Map<String, dynamic>), message: messageApi(res));
      }, tr('Impossible de décliner la proposition'));

  @override
  Future<AvecMessage<ColisModel>> modifierColis(String id, Map<String, dynamic> champs) => appelApi(() async {
        final res = await dio.patch(Env.clientColisId(id), data: champs);
        return (valeur: ColisModel.fromJson(_data(res)['colis'] as Map<String, dynamic>), message: messageApi(res));
      }, tr('Impossible de modifier la demande'));

  @override
  Future<String> ajouterPhotos(String id, List<String> photosPaths) => appelApi(() async {
        final form = FormData();
        for (final chemin in photosPaths) {
          form.files.add(MapEntry('photos', await fichierMultipart(chemin)));
        }
        final res = await dio.post(Env.clientColisPhotos(id), data: form);
        return messageApi(res);
      }, tr('Envoi des photos impossible'));

  @override
  Future<String> deposerVocal(String id, String cheminAudio) => appelApi(() async {
        final form = FormData.fromMap({
          'vocal': await MultipartFile.fromFile(
            cheminAudio,
            filename: 'message_vocal.m4a',
            contentType: DioMediaType('audio', 'mp4'),
          ),
        });
        final res = await dio.post(Env.clientColisVocal(id), data: form);
        return messageApi(res);
      }, tr('Envoi du message vocal impossible'));

  @override
  Future<String> abonnerSuivi(String id,
          {required String canal, required String destination, String profil = 'destinataire'}) =>
      appelApi(() async {
        final res = await dio.post(Env.clientColisAbonnement(id),
            data: {'canal': canal, 'destination': destination.trim(), 'profil': profil});
        return messageApi(res);
      }, tr('Inscription aux alertes impossible'));
}
