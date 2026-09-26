import 'dart:async';

/// Bus d'événements d'authentification.
///
/// Utilisé pour communiquer un logout forcé (401 non récupérable)
/// depuis l'intercepteur Dio vers le widget tree, sans dépendre du BuildContext.
///
/// Usage :
///   // Émettre (depuis l'intercepteur) :
///   AuthEventBus.instance.emitLogout();
///
///   // Écouter (depuis main.dart ou un widget racine) :
///   AuthEventBus.instance.onLogout.listen((_) { ... });
class AuthEventBus {
  AuthEventBus._();
  static final AuthEventBus instance = AuthEventBus._();

  final _logoutController = StreamController<void>.broadcast();

  /// Stream écouté par le widget root pour déclencher le logout
  Stream<void> get onLogout => _logoutController.stream;

  /// Appelé par l'intercepteur Dio quand le refresh échoue (401 définitif)
  void emitLogout() {
    if (!_logoutController.isClosed) {
      _logoutController.add(null);
    }
  }

  void dispose() => _logoutController.close();
}

