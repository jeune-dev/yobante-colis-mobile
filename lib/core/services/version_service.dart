import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../injection_container.dart';
import '../config/env.dart';
import '../i18n/langue.dart';

/// Configuration de version publiée par l'administrateur (`GET /app-version`).
class VersionPubliee {
  final String derniereVersion;
  final String versionMinimale;
  final bool miseAJourForcee;
  final String? titre;
  final String? message;
  final String lienStore;

  const VersionPubliee({
    required this.derniereVersion,
    required this.versionMinimale,
    this.miseAJourForcee = false,
    this.titre,
    this.message,
    required this.lienStore,
  });

  factory VersionPubliee.fromJson(Map<String, dynamic> j) => VersionPubliee(
        derniereVersion: j['derniereVersion'] as String? ?? '0.0.0',
        versionMinimale: j['versionMinimale'] as String? ?? '0.0.0',
        miseAJourForcee: j['miseAJourForcee'] as bool? ?? false,
        titre: j['titre'] as String?,
        message: j['message'] as String?,
        lienStore: j['lienStore'] as String? ?? '',
      );
}

/// Contrôle de version au démarrage : sous la version minimale (ou si
/// l'administrateur force la mise à jour), l'application est bloquée ; une
/// version plus récente disponible est simplement proposée.
class VersionService {
  VersionService._();

  /// Compare deux versions « 1.2.3 » : négatif si [a] < [b].
  static int comparer(String a, String b) {
    List<int> parties(String v) {
      final p = v.split('+').first.split('.').map((x) => int.tryParse(x) ?? 0).toList();
      while (p.length < 3) {
        p.add(0);
      }
      return p;
    }

    final pa = parties(a);
    final pb = parties(b);
    for (var i = 0; i < 3; i++) {
      final d = pa[i] - pb[i];
      if (d != 0) return d;
    }
    return 0;
  }

  /// Vérifie la version et affiche la boîte de dialogue adaptée. Sans réseau ou
  /// sans configuration côté serveur, l'application démarre normalement.
  static Future<void> verifier(BuildContext context) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    VersionPubliee? publiee;
    String actuelle;
    try {
      actuelle = (await PackageInfo.fromPlatform()).version;
      final res = await sl<Dio>().get(
        Env.appVersion,
        queryParameters: {'plateforme': Platform.isIOS ? 'ios' : 'android'},
        options: Options(extra: {'skipAuthInterceptor': true, 'retryCount': 2}),
      );
      final v = res.data['data']?['version'];
      if (v is Map<String, dynamic>) publiee = VersionPubliee.fromJson(v);
    } catch (_) {
      return;
    }
    if (publiee == null || !context.mounted) return;

    final obligatoire = comparer(actuelle, publiee.versionMinimale) < 0 ||
        (publiee.miseAJourForcee && comparer(actuelle, publiee.derniereVersion) < 0);
    final disponible = comparer(actuelle, publiee.derniereVersion) < 0;
    if (!obligatoire && !disponible) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !obligatoire,
      builder: (ctx) => PopScope(
        canPop: !obligatoire,
        child: AlertDialog(
          title: Text(publiee!.titre ?? tr('Mise à jour disponible')),
          content: Text(publiee.message?.isNotEmpty == true
              ? publiee.message!
              : obligatoire
                  ? tr('Cette version de l\'application n\'est plus prise en charge. Installez la mise à jour pour continuer.')
                  : tr('Une nouvelle version (${publiee.derniereVersion}) est disponible.')),
          actions: [
            if (!obligatoire)
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('Plus tard'))),
            ElevatedButton(
              onPressed: () {
                final uri = Uri.tryParse(publiee!.lienStore);
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(tr('Mettre à jour')),
            ),
          ],
        ),
      ),
    );
  }
}
