import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../routes/app_router.dart';
import '../../injection_container.dart';
import 'package:toastification/toastification.dart';
import '../widgets/toast_notif.dart';
import 'token_service.dart';
import 'ouverture_notification.dart';

/// Handler background/terminated — doit être une fonction top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par main() — rien à faire ici
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Firebase absent (iOS sans GoogleService-Info.plist) : les notifications push
  /// sont désactivées sans erreur ; notifications internes et emails continuent.
  static bool get _firebasePret => Firebase.apps.isNotEmpty;

  static StreamSubscription? _foregroundSub;
  static StreamSubscription? _openedAppSub;
  static StreamSubscription? _tokenRefreshSub;

  /// Initialise FCM : permissions + handlers + envoi du token au backend
  static Future<void> init(BuildContext context) async {
    if (!_firebasePret) return;
    // 1. Demander la permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Handler messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Handler message quand l'app est au premier plan
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      // Application ouverte : Android n'affiche pas la notification, on la présente dans l'app
      final notif = message.notification;
      if (notif == null || !context.mounted) return;
      showToast(context, notif.title ?? 'Yobante', notif.body ?? '', ToastificationType.info);
    });

    // 4. Handler tap sur notif quand l'app était en arrière-plan
    _openedAppSub?.cancel();
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) _handleNotificationTap(context, message.data);
    });

    // 5. Handler tap sur notif quand l'app était terminée
    final initial = await _messaging.getInitialMessage();
    if (initial != null && context.mounted) {
      // Petit délai pour laisser le widget tree se construire
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(context, initial.data);
      });
    }

    // 6. Envoyer le token au backend
    await uploadToken();

    // 7. Écouter les refreshs de token
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((_) => uploadToken());
  }

  /// Envoie le token FCM au backend (best-effort).
  /// Public — appelé aussi depuis AuthBloc juste après un login réussi,
  /// sans avoir besoin de BuildContext.
  static Future<void> uploadToken() async {
    if (!_firebasePret) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      // Vérifier que le JWT est valide avant d'envoyer
      final isAuth = await sl<TokenService>().isAuthenticated;
      if (!isAuth) return;

      // Le Dio injecté a déjà l'intercepteur Authorization
      await sl<Dio>().post(
        Env.clientDeviceToken,
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {
      // Best-effort — ne pas bloquer si le backend est down
    }
  }

  /// Navigation lors d'un tap sur notification : le backend joint à chaque push
  /// l'entité concernée (`entite`, `entiteId`) — un colis s'ouvre directement.
  static void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    if (!context.mounted) return;
    final entite = data['entite'] as String?;
    final id = data['entiteId'] as String?;
    if (ouvrirEntiteNotification(context, entite, id)) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (route) => false);
  }
}
