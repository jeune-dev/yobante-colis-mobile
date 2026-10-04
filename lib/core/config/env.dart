import 'package:flutter/foundation.dart';

class Env {
  Env._();

  static const String _apiProduction = 'https://api.yobanterek.com';

  /// Backend lancé sur le Mac de développement (`npm run dev`), joignable par
  /// l'iPhone, le simulateur iOS et l'émulateur Android sur le même Wi-Fi.
  /// À mettre à jour si l'adresse du Mac change (`ipconfig getifaddr en0`).
  static const String _apiLocale = 'http://192.168.1.11:3000';

  /// API utilisée par l'application :
  /// - `--dart-define=API_BASE_URL=…` s'il est fourni ;
  /// - sinon le backend local en mode debug (`flutter run`) ;
  /// - sinon la production (`flutter build`, versions publiées).
  static String get baseUrl {
    const v = String.fromEnvironment('API_BASE_URL');
    if (v.isNotEmpty) return v;
    return kDebugMode ? _apiLocale : _apiProduction;
  }

  /// Préfixe versionné recommandé par le contrat d'API (les chemins sans préfixe restent servis).
  static const String prefixeApi = '/api/v1';
  static String get apiUrl => '$baseUrl$prefixeApi';

  // ── AUTH ──────────────────────────────────────────────────────────────────
  static const String authRegister   = '/auth/register';
  static const String authLogin      = '/auth/login';
  static const String authLogout     = '/auth/logout';
  static const String authRefresh    = '/auth/refresh-token';
  static const String authForgot     = '/auth/forgot-password';
  static const String authReset      = '/auth/reset-password';
  static const String authChangePass = '/auth/change-password';
  static const String authResendVerification = '/auth/resend-verification';

  // ── CLIENT — COLIS ────────────────────────────────────────────────────────
  static const String clientColis      = '/client/colis';
  static const String clientColisRecus = '/client/colis/recus';
  static String clientColisId(String id)      => '/client/colis/$id';
  static String clientColisSuivi(String id)   => '/client/colis/$id/suivi';
  static String clientColisAnnuler(String id) => '/client/colis/$id/annuler';
  static String clientColisAccepter(String id) => '/client/colis/$id/proposition/accepter';
  static String clientColisRefuser(String id)  => '/client/colis/$id/proposition/refuser';
  static String clientColisEtiquettes(String id) => '/client/colis/$id/etiquettes';
  static String clientColisBordereau(String id)  => '/client/colis/$id/bordereau';
  static String clientColisFactureCommerciale(String id) => '/client/colis/$id/facture-commerciale';
  static String clientColisPhotos(String id)     => '/client/colis/$id/photos';
  static String clientColisVocal(String id)      => '/client/colis/$id/vocal';
  static String clientColisAbonnement(String id) => '/client/colis/$id/abonnement-suivi';

  // ── PUBLIC — SERVICES / POINTS DE COLLECTE ────────────────────────────────
  static const String publicServices      = '/public/services';
  static const String publicPointsCollecte = '/public/points-collecte';

  // ── PUBLIC — CATALOGUE ET ACCUEIL (cahier des charges) ────────────────────
  static const String publicConfiguration = '/public/configuration';
  static const String publicCategories    = '/public/categories';
  static const String publicAccueil       = '/public/accueil';
  static const String publicTournees      = '/public/tournees-collecte';
  static const String publicTarifs        = '/public/tarifs';
  static const String publicEmballages    = '/public/emballages';

  // ── CLIENT — PROFIL ───────────────────────────────────────────────────────
  static const String clientProfil        = '/client/profil';
  static const String clientProfilAvatar  = '/client/profil/avatar';
  static const String clientDeviceToken   = '/client/profil/device-token';
  static const String clientPreferences   = '/client/profil/preferences';
  static const String clientParrainage    = '/client/profil/parrainage';
  static const String clientJustificatifPro = '/client/profil/justificatif-pro';
  // Preuve de possession du numéro : exigée pour consulter les colis reçus
  static const String clientTelephoneCode     = '/client/profil/telephone/code';
  static const String clientTelephoneVerifier = '/client/profil/telephone/verifier';

  // ── CLIENT — COMPTE (RGPD) ────────────────────────────────────────────────
  static const String clientCompte = '/client/compte';
  static const String clientCompteExport = '/client/compte/export';

  // ── CLIENT — ENLÈVEMENTS À DOMICILE ───────────────────────────────────────
  static const String clientEnlevements        = '/client/enlevements';
  static const String clientEnlevementsCreneaux = '/client/enlevements/creneaux';
  static String clientEnlevementId(String id)      => '/client/enlevements/$id';
  static String clientEnlevementAnnuler(String id) => '/client/enlevements/$id/annuler';

  // ── CLIENT — CARNET D'ADRESSES ────────────────────────────────────────────
  static const String clientAdresses = '/client/adresses';
  static String clientAdresseId(String id)     => '/client/adresses/$id';
  static String clientAdresseDefaut(String id) => '/client/adresses/$id/defaut';

  // ── AVIS CLIENTS ──────────────────────────────────────────────────────────
  static const String publicAvis = '/public/avis';
  static const String clientAvis = '/client/avis';
  static String clientAvisId(String id) => '/client/avis/$id';

  // ── MESURE D'AUDIENCE ─────────────────────────────────────────────────────
  static const String publicVisites = '/public/visites';

  // ── CLIENT — RÉCLAMATIONS (service après-vente) ───────────────────────────
  static const String clientReclamations = '/client/reclamations';
  static String clientReclamationId(String id)       => '/client/reclamations/$id';
  static String clientReclamationMessages(String id) => '/client/reclamations/$id/messages';
  static String clientReclamationNote(String id)     => '/client/reclamations/$id/note';

  // ── PUBLIC — VERSION DE L'APPLICATION / FAQ ───────────────────────────────
  static const String appVersion = '/app-version';
  static const String publicFaq  = '/public/faq';

  // ── CLIENT — NOTIFICATIONS ────────────────────────────────────────────────
  static const String clientNotifications   = '/client/notifications';
  static const String clientNotifNonLues    = '/client/notifications/non-lues';
  static const String clientNotifToutesLues = '/client/notifications/toutes-lues';
  static String clientNotifLue(String id)  => '/client/notifications/$id/lue';
  static String clientNotifId(String id)   => '/client/notifications/$id';

  // ── CLIENT — PAIEMENTS / FACTURES ─────────────────────────────────────────
  static const String clientFactures          = '/client/paiements/factures';
  static String clientFactureId(String id)    => '/client/paiements/factures/$id';
  static String clientFactureDocument(String id) => '/client/paiements/factures/$id/document';
  static const String clientPaiements        = '/client/paiements';
  static const String clientPaiementsEncours = '/client/paiements/encours';
  static const String clientPaiementsMethodes = '/client/paiements/methodes';

  // ── PUBLIC — SUIVI / VILLES / DEVIS (aucune authentification requise) ─────
  static String publicSuivi(String reference) => '/public/suivi/$reference';
  static const String publicVilles = '/public/villes';
  static const String publicDevis  = '/public/devis';
  static const String clientDevis  = '/client/colis/devis';
}
