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

  // ── ADMIN — DASHBOARD ─────────────────────────────────────────────────────
  static const String adminDashStats         = '/admin/dashboard/stats';
  static const String adminDashColisStatut   = '/admin/dashboard/colis-par-statut';
  static const String adminDashDerniersColis = '/admin/dashboard/derniers-colis';
  static const String adminDashDerniersUsers = '/admin/dashboard/derniers-utilisateurs';

  // ── ADMIN — COLIS ─────────────────────────────────────────────────────────
  static const String adminColis              = '/admin/colis';
  static const String adminColisStats         = '/admin/colis/statistiques';
  static String adminColisId(String id)       => '/admin/colis/$id';
  static String adminColisStatut(String id)   => '/admin/colis/$id/statut';
  static String adminColisPhotos(String id)   => '/admin/colis/$id/photos';

  // ── ADMIN — USERS ─────────────────────────────────────────────────────────
  static const String adminUsers              = '/admin/users';
  static String adminUserId(String id)        => '/admin/users/$id';
  static String adminUserColis(String id)     => '/admin/users/$id/colis';
  static String adminUserActiver(String id)   => '/admin/users/$id/activer';
  static String adminUserDesact(String id)    => '/admin/users/$id/desactiver';

  // ── ADMIN — ADMINS ────────────────────────────────────────────────────────
  static const String adminAdmins         = '/admin/admins';
  static String adminAdminId(String id)   => '/admin/admins/$id';

  // ── ADMIN — VILLES ────────────────────────────────────────────────────────
  static const String adminVilles         = '/admin/villes';
  static String adminVilleId(String id)   => '/admin/villes/$id';

  // ── ADMIN — TARIFS ────────────────────────────────────────────────────────
  static const String adminTarifs           = '/admin/tarifs';
  static const String adminTarifsCalculer   = '/admin/tarifs/calculer-prix';
  static String adminTarifId(String id)     => '/admin/tarifs/$id';

  // ── ADMIN — FACTURES ──────────────────────────────────────────────────────
  static const String adminFactures               = '/admin/factures';
  static String adminFactureId(String id)         => '/admin/factures/$id';
  static String adminFactureAnnuler(String id)    => '/admin/factures/$id/annuler';

  // ── ADMIN — PAIEMENTS ─────────────────────────────────────────────────────
  static const String adminPaiements                  = '/admin/paiements';
  static String adminPaiementId(String id)            => '/admin/paiements/$id';
  static String adminPaiementFacture(String fId)      => '/admin/paiements/factures/$fId';
  static String adminPaiementRembourser(String id)    => '/admin/paiements/$id/rembourser';
}
