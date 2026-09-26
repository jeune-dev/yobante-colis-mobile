import '../demo/demo_config.dart';
import '../../injection_container.dart';
import 'token_service.dart';

/// Statut de connexion de l'utilisateur, conscient du mode démo
/// (voir demo_config.dart) — à utiliser partout où l'UI doit savoir si
/// l'utilisateur est authentifié, à la place d'un accès direct à
/// [TokenService].
Future<bool> isUserAuthenticated() {
  if (kDemoMode) return Future.value(true);
  return sl<TokenService>().isAuthenticated;
}
