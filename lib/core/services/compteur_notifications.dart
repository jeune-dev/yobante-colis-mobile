import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../injection_container.dart';
import 'auth_status.dart';

/// Nombre de notifications non lues, partagé par toute l'application (pastilles
/// de l'onglet Compte, de la cloche, du menu latéral…).
///
/// Il se met à jour tout seul :
/// - au démarrage, puis toutes les [intervalle] tant que l'application est au
///   premier plan, et à chaque retour dans l'application ;
/// - +1 à la réception d'une notification push ([nouvelleNotification]) ;
/// - -1 quand le client ouvre une notification ([notificationLue]), 0 quand il
///   marque tout comme lu, -1 s'il supprime une notification non lue.
/// La valeur du serveur fait toujours foi : chaque rafraîchissement la recale.
class CompteurNotifications extends ValueNotifier<int> with WidgetsBindingObserver {
  CompteurNotifications._() : super(0);

  static final CompteurNotifications instance = CompteurNotifications._();

  static const Duration intervalle = Duration(seconds: 60);

  Timer? _minuteur;
  bool _demarre = false;

  /// Lance le suivi automatique (à l'ouverture de l'espace connecté).
  void demarrer() {
    if (_demarre) {
      rafraichir();
      return;
    }
    _demarre = true;
    WidgetsBinding.instance.addObserver(this);
    rafraichir();
    _relancerMinuteur();
  }

  /// Arrête le suivi et remet le compteur à zéro (déconnexion).
  void arreter() {
    if (_demarre) WidgetsBinding.instance.removeObserver(this);
    _demarre = false;
    _minuteur?.cancel();
    _minuteur = null;
    value = 0;
  }

  void _relancerMinuteur() {
    _minuteur?.cancel();
    _minuteur = Timer.periodic(intervalle, (_) => rafraichir());
  }

  /// Recale le compteur sur la valeur du serveur (sans effet hors connexion).
  Future<void> rafraichir() async {
    if (!await isUserAuthenticated()) {
      value = 0;
      return;
    }
    final resultat = await sl<NotificationsRepository>().getNonLuesCount();
    resultat.fold((_) {}, (total) => value = total < 0 ? 0 : total);
  }

  /// Notification push reçue : +1 immédiat, puis recalage sur le serveur.
  void nouvelleNotification() {
    value = value + 1;
    rafraichir();
  }

  /// Une notification non lue vient d'être ouverte ou supprimée.
  void notificationLue() {
    if (value > 0) value = value - 1;
  }

  /// Toutes les notifications ont été marquées comme lues.
  void toutesLues() => value = 0;

  /// Valeur connue après un chargement complet de la liste.
  void definir(int total) => value = total < 0 ? 0 : total;

  // Pas de requêtes en arrière-plan ; mise à jour dès le retour dans l'application
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_demarre) return;
    if (state == AppLifecycleState.resumed) {
      rafraichir();
      _relancerMinuteur();
    } else if (state == AppLifecycleState.paused) {
      _minuteur?.cancel();
    }
  }
}
