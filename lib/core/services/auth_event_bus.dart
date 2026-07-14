import 'dart:async';

/// Bus d'Ã©vÃ©nements d'authentification.
///
/// UtilisÃ© pour communiquer un logout forcÃ© (401 non rÃ©cupÃ©rable)
/// depuis l'intercepteur Dio vers le widget tree, sans dÃ©pendre du BuildContext.
///
/// Usage :
///   // Ã‰mettre (depuis l'intercepteur) :
///   AuthEventBus.instance.emitLogout();
///
///   // Ã‰couter (depuis main.dart ou un widget racine) :
///   AuthEventBus.instance.onLogout.listen((_) { ... });
class AuthEventBus {
  AuthEventBus._();
  static final AuthEventBus instance = AuthEventBus._();

  final _logoutController = StreamController<void>.broadcast();

  /// Stream Ã©coutÃ© par le widget root pour dÃ©clencher le logout
  Stream<void> get onLogout => _logoutController.stream;

  /// AppelÃ© par l'intercepteur Dio quand le refresh Ã©choue (401 dÃ©finitif)
  void emitLogout() {
    if (!_logoutController.isClosed) {
      _logoutController.add(null);
    }
  }

  void dispose() => _logoutController.close();
}

