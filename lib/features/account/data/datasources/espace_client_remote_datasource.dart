import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/fichier_upload.dart';

/// Programme de parrainage du client connecté.
class Parrainage {
  final bool actif;
  final String? code;
  final double creditDisponibleEur;
  final double gainParFilleulEur;
  final double remiseFilleulPourcent;
  final bool bonusBienvenueDisponible;
  final List<({String prenom, String inscritLe, bool premiereExpedition})> filleuls;

  const Parrainage({
    required this.actif,
    this.code,
    this.creditDisponibleEur = 0,
    this.gainParFilleulEur = 0,
    this.remiseFilleulPourcent = 0,
    this.bonusBienvenueDisponible = false,
    this.filleuls = const [],
  });

  factory Parrainage.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return Parrainage(
      actif: j['actif'] as bool? ?? false,
      code: j['code'] as String?,
      creditDisponibleEur: d(j['creditDisponibleEur']),
      gainParFilleulEur: d(j['gainParFilleulEur']),
      remiseFilleulPourcent: d(j['remiseFilleulPourcent']),
      bonusBienvenueDisponible: j['bonusBienvenueDisponible'] as bool? ?? false,
      filleuls: (j['filleuls'] as List? ?? [])
          .map((f) => (
                prenom: f['prenom'] as String? ?? '',
                inscritLe: f['inscritLe'] as String? ?? '',
                premiereExpedition: f['premiereExpedition'] as bool? ?? false,
              ))
          .toList(),
    );
  }
}

/// Profil étendu utile à l'espace client (préférences, tarif professionnel).
class ProfilClient {
  final String? codePostal;
  final String typeCompte;
  final String? numeroIdentificationFiscale;
  final bool justificatifProValide;
  final String? justificatifProUrl;
  final bool notificationsEmail;
  final bool notificationsPush;
  final bool notificationsWhatsapp;
  final bool emailVerifie;
  final String? telephone;

  /// Numéro prouvé par un code WhatsApp : condition d'accès aux colis reçus.
  final bool telephoneVerifie;

  const ProfilClient({
    this.codePostal,
    this.typeCompte = 'particulier',
    this.numeroIdentificationFiscale,
    this.justificatifProValide = false,
    this.justificatifProUrl,
    this.notificationsEmail = true,
    this.notificationsPush = true,
    this.notificationsWhatsapp = true,
    this.emailVerifie = false,
    this.telephone,
    this.telephoneVerifie = false,
  });

  factory ProfilClient.fromJson(Map<String, dynamic> j) => ProfilClient(
        codePostal: j['codePostal'] as String?,
        typeCompte: j['typeCompte'] as String? ?? 'particulier',
        numeroIdentificationFiscale: j['numeroIdentificationFiscale'] as String?,
        justificatifProValide: j['justificatifProValide'] as bool? ?? false,
        justificatifProUrl: j['justificatifProUrl'] as String?,
        notificationsEmail: j['notificationsEmail'] as bool? ?? true,
        notificationsPush: j['notificationsPush'] as bool? ?? true,
        notificationsWhatsapp: j['notificationsWhatsapp'] as bool? ?? true,
        emailVerifie: j['emailVerifie'] as bool? ?? false,
        telephone: j['telephone'] as String?,
        telephoneVerifie: j['telephoneVerifie'] as bool? ?? false,
      );
}

class EspaceClientRemoteDataSource {
  final Dio dio;
  EspaceClientRemoteDataSource({required this.dio});

  Map<String, dynamic> _data(Response res) => res.data['data'] as Map<String, dynamic>;

  Future<ProfilClient> getProfil() => appelApi(() async {
        final res = await dio.get(Env.clientProfil);
        return ProfilClient.fromJson(_data(res)['utilisateur'] as Map<String, dynamic>);
      });

  /// Renvoie le profil à jour et le message du backend.
  Future<({ProfilClient profil, String message})> modifierProfil(Map<String, dynamic> champs) =>
      appelApi(() async {
        final res = await dio.put(Env.clientProfil, data: champs);
        return (
          profil: ProfilClient.fromJson(_data(res)['utilisateur'] as Map<String, dynamic>),
          message: messageApi(res),
        );
      }, tr('Impossible d\'enregistrer le profil'));

  Future<({ProfilClient profil, String message})> modifierPreferences(Map<String, bool> preferences) =>
      appelApi(() async {
        final res = await dio.put(Env.clientPreferences, data: preferences);
        return (
          profil: ProfilClient.fromJson(_data(res)['utilisateur'] as Map<String, dynamic>),
          message: messageApi(res),
        );
      }, tr('Impossible d\'enregistrer vos préférences'));

  Future<Parrainage> getParrainage() => appelApi(() async {
        final res = await dio.get(Env.clientParrainage);
        return Parrainage.fromJson(_data(res)['parrainage'] as Map<String, dynamic>);
      });

  /// Dépose le justificatif NINEA / Kbis (image ou PDF) pour le tarif professionnel.
  Future<String> deposerJustificatif(String chemin) => appelApi(() async {
        final form = FormData.fromMap({'justificatif': await fichierMultipart(chemin, pdfAccepte: true)});
        final res = await dio.post(Env.clientJustificatifPro, data: form);
        return messageApi(res);
      }, tr('Envoi du justificatif impossible'));

  /// Envoie un code à 6 chiffres par WhatsApp au numéro du compte.
  /// [dejaVerifie] : le numéro l'était déjà, aucun code n'a été envoyé.
  Future<({String message, bool dejaVerifie})> demanderCodeTelephone() => appelApi(() async {
        final res = await dio.post(Env.clientTelephoneCode);
        final message = messageApi(res);
        final data = res.data is Map ? res.data['data'] : null;
        return (
          message: message,
          // Le texte n'est consulté que pour un backend antérieur au drapeau
          dejaVerifie: (data is Map && data['dejaVerifie'] == true) || message.contains('déjà vérifié'),
        );
      }, tr('Envoi du code impossible'));

  /// Vérifie le code reçu ; ouvre l'accès aux colis dont le compte est destinataire.
  Future<String> verifierTelephone(String code) => appelApi(() async {
        final res = await dio.post(Env.clientTelephoneVerifier, data: {'code': code});
        return messageApi(res);
      }, tr('Code invalide ou expiré'));

  /// Suppression définitive du compte (RGPD) : le mot de passe est redemandé.
  Future<String> supprimerCompte({required String password, String? motif}) => appelApi(() async {
        final res = await dio.delete(Env.clientCompte, data: {
          'password': password,
          if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
        });
        return messageApi(res);
      }, tr('Suppression du compte impossible'));

  /// Export des données personnelles (RGPD art. 20), tel que renvoyé par le backend.
  Future<Map<String, dynamic>> exporterDonnees() => appelApi(() async {
        final res = await dio.get(Env.clientCompteExport);
        return _data(res)['export'] as Map<String, dynamic>? ?? {};
      }, tr('Export de vos données impossible'));
}
