import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../injection_container.dart';
import '../config/env.dart';

/// UUID v4 aléatoire (générateur cryptographique).
String genererUuidV4() {
  final r = Random.secure();
  final o = List<int>.generate(16, (_) => r.nextInt(256));
  o[6] = (o[6] & 0x0f) | 0x40;
  o[8] = (o[8] & 0x3f) | 0x80;
  final h = o.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Mesure d'audience (`POST /public/visites`) et identifiant anonyme de
/// l'installation, envoyé en `X-Visiteur-Id` pour relier une simulation de
/// devis à la commande qui suit (taux de conversion).
///
/// - `visiteurId` : généré une fois, conservé ;
/// - `sessionId` : un par lancement, renouvelé si le backend répond `sessionExpiree` ;
/// - un événement `page` par écran, un `ping` toutes les 45 s au premier plan.
class MesureAudience with WidgetsBindingObserver {
  MesureAudience._();
  static final MesureAudience instance = MesureAudience._();

  static const _cleVisiteur = 'visiteur_id';
  static const _intervallePing = Duration(seconds: 45);

  String? _visiteurId;
  String _sessionId = genererUuidV4();
  Timer? _ping;
  String? _dernierePage;

  /// Identifiant anonyme de l'installation (créé au premier appel).
  String get visiteurId {
    if (_visiteurId != null) return _visiteurId!;
    final prefs = sl<SharedPreferences>();
    var id = prefs.getString(_cleVisiteur);
    if (id == null || id.isEmpty) {
      id = genererUuidV4();
      prefs.setString(_cleVisiteur, id);
    }
    return _visiteurId = id;
  }

  String get _plateforme => Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';

  void demarrer() {
    WidgetsBinding.instance.addObserver(this);
    _relancerPing();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _relancerPing();
      if (_dernierePage != null) page(_dernierePage!);
    } else if (state == AppLifecycleState.paused) {
      _ping?.cancel();
    }
  }

  void _relancerPing() {
    _ping?.cancel();
    _ping = Timer.periodic(_intervallePing, (_) => _envoyer('ping'));
  }

  /// Affichage d'un écran.
  void page(String nom) {
    _dernierePage = nom;
    _envoyer('page', page: nom);
  }

  /// Best-effort : la mesure ne doit jamais gêner l'utilisateur.
  Future<void> _envoyer(String evenement, {String? page}) async {
    try {
      final res = await sl<Dio>().post(
        Env.publicVisites,
        data: {
          'sessionId': _sessionId,
          'visiteurId': visiteurId,
          'plateforme': _plateforme,
          'evenement': evenement,
          'page': ?page,
        },
        // Jeton joint s'il existe : la visite est alors rattachée au compte
        options: Options(extra: {'retryCount': 2}),
      );
      if (res.data['data']?['sessionExpiree'] == true) {
        _sessionId = genererUuidV4();
        if (evenement == 'page') await _envoyer(evenement, page: page);
      }
    } catch (_) {}
  }
}

/// Envoie un événement `page` à chaque écran nommé poussé dans le navigateur.
class ObservateurAudience extends NavigatorObserver {
  void _noter(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    var nom = route.settings.name;
    // Écrans poussés sans nom : le type de la page sert de nom d'écran
    if ((nom == null || nom.isEmpty) && route is MaterialPageRoute) {
      final contexte = route.navigator?.context;
      if (contexte != null) {
        try {
          nom = route.builder(contexte).runtimeType.toString();
        } catch (_) {}
      }
    }
    if (nom != null && nom.isNotEmpty) MesureAudience.instance.page(nom);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _noter(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _noter(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _noter(newRoute);
}
