import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/user_role.dart';
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

/// Rôle du compte connecté, enregistré à l'ouverture de session : décide entre
/// l'espace client et l'espace du personnel (coursier, agent de point, admin).
Future<UserRole> roleCourant() async {
  if (kDemoMode) return UserRole.client;
  try {
    return UserRoleX.fromString(await sl<FlutterSecureStorage>().read(key: 'user_role'));
  } catch (_) {
    return UserRole.client;
  }
}
