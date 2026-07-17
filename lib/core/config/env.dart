class Env {
  Env._();

  static String get baseUrl {
    const v = String.fromEnvironment('API_BASE_URL');
    // 10.0.2.2 = localhost depuis l'émulateur Android
    return v.isEmpty ? 'http://10.0.2.2:9000' : v;
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  static const String authRegister   = '/auth/register';
  static const String authLogin      = '/auth/login';
  static const String authLogout     = '/auth/logout';
  static const String authRefresh    = '/auth/refresh-token';
  static const String authForgot     = '/auth/forgot-password';
  static const String authReset      = '/auth/reset-password';
  static const String authChangePass = '/auth/change-password';

  // ── CLIENT — COLIS ────────────────────────────────────────────────────────
  static const String clientColis = '/client/colis';
  static String clientColisId(String id)      => '/client/colis/$id';
  static String clientColisSuivi(String id)   => '/client/colis/$id/suivi';
  static String clientColisAnnuler(String id) => '/client/colis/$id/annuler';

  // ── CLIENT — PROFIL ───────────────────────────────────────────────────────
  static const String clientProfil        = '/client/profil';
  static const String clientProfilAvatar  = '/client/profil/avatar';
  static const String accountDeviceToken  = '/account/device-token';

  // ── CLIENT — NOTIFICATIONS ────────────────────────────────────────────────
  static const String clientNotifications   = '/client/notifications';
  static const String clientNotifNonLues    = '/client/notifications/non-lues';
  static const String clientNotifToutesLues = '/client/notifications/toutes-lues';
  static String clientNotifLue(String id)  => '/client/notifications/$id/lue';

  // ── CLIENT — PAIEMENTS / FACTURES ─────────────────────────────────────────
  static const String clientFactures          = '/client/paiements/factures';
  static String clientFactureId(String id)    => '/client/paiements/factures/$id';

  // ── ADMIN — VILLES (endpoint utilisé par le client pour lister les villes) ─
  static const String adminVilles = '/admin/villes';
}
