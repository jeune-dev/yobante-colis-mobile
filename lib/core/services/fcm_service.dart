import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../config/user_role.dart';
import '../routes/app_router.dart';
import '../../injection_container.dart';
import 'token_service.dart';

/// Handler background/terminated â€” doit Ãªtre une fonction top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est dÃ©jÃ  initialisÃ© par main() â€” rien Ã  faire ici
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Initialise FCM : permissions + handlers + envoi du token au backend
  static Future<void> init(BuildContext context) async {
    // 1. Demander la permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Handler messages en arriÃ¨re-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Handler message quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((message) {
      // On ne fait rien en foreground â€” la notif systÃ¨me apparaÃ®t automatiquement
    });

    // 4. Handler tap sur notif quand l'app Ã©tait en arriÃ¨re-plan
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) _handleNotificationTap(context, message.data);
    });

    // 5. Handler tap sur notif quand l'app Ã©tait terminÃ©e
    final initial = await _messaging.getInitialMessage();
    if (initial != null && context.mounted) {
      // Petit dÃ©lai pour laisser le widget tree se construire
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(context, initial.data);
      });
    }

    // 6. Envoyer le token au backend
    await _uploadToken();

    // 7. Ã‰couter les refreshs de token
    _messaging.onTokenRefresh.listen((_) => _uploadToken());
  }

  /// Envoie le token FCM au backend (best-effort).
  /// Public â€” appelÃ© aussi depuis AuthBloc juste aprÃ¨s un login rÃ©ussi,
  /// sans avoir besoin de BuildContext.
  static Future<void> uploadToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      // VÃ©rifier que le JWT est valide avant d'envoyer
      final isAuth = await sl<TokenService>().isAuthenticated;
      if (!isAuth) return;

      // Le Dio injectÃ© a dÃ©jÃ  l'intercepteur Authorization
      await sl<Dio>().post(
        Env.accountDeviceToken,
        data: {'token': token, 'platform': 'android'},
      );
    } catch (_) {
      // Best-effort â€” ne pas bloquer si le backend est down
    }
  }

  // Alias privÃ© pour l'usage interne (init + onTokenRefresh)
  static Future<void> _uploadToken() => uploadToken();

  /// Navigation lors d'un tap sur notification
  static Future<void> _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    if (!context.mounted) return;
    final role = await _getUserRole();
    if (!context.mounted) return;

    final userRole = UserRoleX.fromString(role);
    if (userRole.isAdmin) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.adminRoute, (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (route) => false);
    }
  }

  static Future<String?> _getUserRole() async {
    try {
      return await sl<FlutterSecureStorage>().read(key: 'user_role');
    } catch (_) {
      return null;
    }
  }
}

