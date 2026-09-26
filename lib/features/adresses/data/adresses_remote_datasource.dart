import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';

/// Carnet d'adresses du client (`/client/adresses`) : expéditeurs et
/// destinataires habituels, réutilisables lors d'une expédition.

Map<String, String> get kTypesAdresse => {
  'destinataire': tr('Destinataire'),
  'expediteur': tr('Expéditeur'),
  'les_deux': tr('Expéditeur et destinataire'),
};

class AdresseCarnet extends Equatable {
  final String id;
  final String libelle;
  final String type;
  final String nom;
  final String? entreprise;
  final String telephone;
  final String? telephoneSecondaire;
  final String? email;
  final String pays;
  final String villeId;
  final String? villeNom;
  final String adresse;
  final String? complementAdresse;
  final String? quartier;
  final String? arrondissement;
  final String? departement;
  final String? pointRepere;
  final String? codePostal;
  final String? instructions;
  final String? pointRetraitPrefereId;
  final bool parDefaut;

  const AdresseCarnet({
    required this.id,
    required this.libelle,
    this.type = 'destinataire',
    required this.nom,
    this.entreprise,
    required this.telephone,
    this.telephoneSecondaire,
    this.email,
    required this.pays,
    required this.villeId,
    this.villeNom,
    required this.adresse,
    this.complementAdresse,
    this.quartier,
    this.arrondissement,
    this.departement,
    this.pointRepere,
    this.codePostal,
    this.instructions,
    this.pointRetraitPrefereId,
    this.parDefaut = false,
  });

  bool get estDestinataire => type != 'expediteur';
  bool get estExpediteur => type != 'destinataire';

  String get resume => [adresse, quartier, villeNom].whereType<String>().where((e) => e.isNotEmpty).join(', ');

  factory AdresseCarnet.fromJson(Map<String, dynamic> j) => AdresseCarnet(
        id: j['id'] as String? ?? '',
        libelle: j['libelle'] as String? ?? '',
        type: j['type'] as String? ?? 'destinataire',
        nom: j['nom'] as String? ?? '',
        entreprise: j['entreprise'] as String?,
        telephone: j['telephone'] as String? ?? '',
        telephoneSecondaire: j['telephoneSecondaire'] as String?,
        email: j['email'] as String?,
        pays: j['pays'] as String? ?? 'SN',
        villeId: j['villeId'] as String? ?? '',
        villeNom: (j['ville'] as Map<String, dynamic>?)?['nom'] as String?,
        adresse: j['adresse'] as String? ?? '',
        complementAdresse: j['complementAdresse'] as String?,
        quartier: j['quartier'] as String?,
        arrondissement: j['arrondissement'] as String?,
        departement: j['departement'] as String?,
        pointRepere: j['pointRepere'] as String?,
        codePostal: j['codePostal'] as String?,
        instructions: j['instructions'] as String?,
        pointRetraitPrefereId: j['pointRetraitPrefereId'] as String?,
        parDefaut: j['parDefaut'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, parDefaut, libelle];
}

class AdressesRemoteDataSource {
  final Dio dio;
  AdressesRemoteDataSource({required this.dio});

  AdresseCarnet _adresse(Response res) =>
      AdresseCarnet.fromJson(res.data['data']['adresse'] as Map<String, dynamic>);

  Future<List<AdresseCarnet>> getAdresses({String? type, String? pays, String? search}) => appelApi(() async {
        final res = await dio.get(Env.clientAdresses, queryParameters: {
          'limit': 100,
          'type': ?type,
          'pays': ?pays,
          if (search != null && search.isNotEmpty) 'search': search,
        });
        return (res.data['data']['adresses'] as List? ?? [])
            .map((a) => AdresseCarnet.fromJson(a as Map<String, dynamic>))
            .toList();
      }, tr('Impossible de charger votre carnet d\'adresses'));

  Future<AdresseCarnet> getAdresse(String id) =>
      appelApi(() async => _adresse(await dio.get(Env.clientAdresseId(id))), tr('Adresse introuvable'));

  /// Champs acceptés par le backend : libelle, type, nom, entreprise, telephone,
  /// telephoneSecondaire, email, pays, villeId, adresse, complementAdresse,
  /// quartier, codePostal, latitude, longitude, instructions,
  /// pointRetraitPrefereId, parDefaut.
  Future<AdresseCarnet> creer(Map<String, dynamic> champs) => appelApi(
      () async => _adresse(await dio.post(Env.clientAdresses, data: champs)), tr('Impossible d\'ajouter l\'adresse'));

  Future<AdresseCarnet> modifier(String id, Map<String, dynamic> champs) => appelApi(
      () async => _adresse(await dio.put(Env.clientAdresseId(id), data: champs)),
      tr('Impossible de modifier l\'adresse'));

  Future<AdresseCarnet> definirParDefaut(String id) => appelApi(
      () async => _adresse(await dio.patch(Env.clientAdresseDefaut(id), data: const {})),
      tr('Impossible de définir l\'adresse par défaut'));

  Future<void> supprimer(String id) =>
      appelApi(() async => dio.delete(Env.clientAdresseId(id)), tr('Impossible de supprimer l\'adresse'));
}
