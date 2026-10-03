/// Mode démonstration : contenu réaliste, sans authentification ni appel
/// réseau, pour présenter l'application à un client. Toutes les données
/// (colis, factures, notifications, profil, villes) sont générées
/// localement — voir demo_data.dart.
///
/// Désactivé par défaut (flux réel : connexion + API backend). Pour une
/// présentation ou des captures d'écran Play Store :
///   flutter run --dart-define=DEMO_MODE=true
/// Valeur fixée à la compilation : un build de production ne l'active jamais.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');
