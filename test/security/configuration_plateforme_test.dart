import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/demo/demo_config.dart';

/// Tests de sécurité — configuration des plateformes et du build.
///
/// Comme le garde-fou du pinning TLS de sign, ces tests lisent les fichiers
/// de configuration natifs : une régression (HTTP en clair, FileProvider
/// exporté, mode démo, capture d'écran…) fait échouer `flutter test` AVANT
/// la publication sur les stores.
void main() {
  String lire(String chemin) {
    final f = File(chemin);
    expect(f.existsSync(), isTrue, reason: '$chemin introuvable');
    return f.readAsStringSync();
  }

  /// Une balise XML, commentaires retirés (un exemple commenté ne compte pas).
  String sansCommentaires(String xml) => xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  group('Backend', () {
    test('la production est en HTTPS et utilisée par défaut (VULN-H03)', () {
      expect(Uri.parse(Env.apiProduction).scheme, 'https');
      expect(Env.baseUrl, Env.apiProduction);
      expect(Env.estBackendLocal, isFalse);
    });

    test('dart_defines.json (versionné) vise la production en HTTPS', () {
      final defines = lire('dart_defines.json');
      expect(defines, contains('"API_BASE_URL": "${Env.apiProduction}"'));
      expect(defines, isNot(contains('http://')));
    });

    test('le mode démo est désactivé par défaut', () {
      expect(kDemoMode, isFalse,
          reason: 'Un build sans --dart-define=DEMO_MODE=true ne doit jamais contourner l\'authentification');
    });
  });

  group('Android — réseau', () {
    final release = 'android/app/src/main/res/xml/network_security_config.xml';
    final debug = 'android/app/src/debug/res/xml/network_security_config.xml';

    test('le manifeste applique la configuration réseau', () {
      expect(lire('android/app/src/main/AndroidManifest.xml'),
          contains('android:networkSecurityConfig="@xml/network_security_config"'));
    });

    test('release : aucun trafic HTTP en clair (VULN-H03)', () {
      final xml = sansCommentaires(lire(release));
      expect(xml, contains('<base-config cleartextTrafficPermitted="false">'));
      expect(xml, isNot(contains('cleartextTrafficPermitted="true"')));
      expect(xml, isNot(contains('src="user"')),
          reason: 'Les certificats installés par l\'utilisateur permettraient une interception (proxy)');
    });

    test('debug : HTTP en clair limité au réseau local', () {
      final xml = sansCommentaires(lire(debug));
      expect(xml, contains('<base-config cleartextTrafficPermitted="false">'));
      final domaines = RegExp(r'<domain[^>]*>([^<]+)</domain>').allMatches(xml).map((m) => m.group(1)!.trim());
      for (final d in domaines) {
        final local = d == 'localhost' ||
            d == '10.0.2.2' ||
            d.startsWith('127.') ||
            d.startsWith('192.168.') ||
            d.startsWith('10.');
        expect(local, isTrue, reason: 'Domaine non local autorisé en clair : $d');
      }
      expect(xml, isNot(contains('includeSubdomains="true"')));
    });
  });

  group('Android — application', () {
    String manifeste() => sansCommentaires(lire('android/app/src/main/AndroidManifest.xml'));

    test('FileProvider non exporté, chemins restreints (VULN-M04)', () {
      final provider = RegExp(r'<provider.*?</provider>', dotAll: true).firstMatch(manifeste())!.group(0)!;
      expect(provider, contains('android:exported="false"'));

      final chemins = sansCommentaires(lire('android/app/src/main/res/xml/file_provider_paths.xml'));
      expect(chemins, isNot(contains('<root-path')), reason: 'root-path exposerait tout le système de fichiers');
      expect(chemins, isNot(contains('<external-path')), reason: 'external-path exposerait le stockage partagé');
      for (final m in RegExp(r'path="([^"]*)"').allMatches(chemins)) {
        expect(m.group(1), isNotEmpty, reason: 'Un path vide partage tout le répertoire');
        expect(m.group(1), isNot(anyOf('.', '/')), reason: 'Un path racine partage tout le répertoire');
      }
    });

    test('seule l\'activité de lancement est exportée', () {
      final exportees = RegExp(r'<(activity|service|receiver|provider)[^>]*android:exported="true"', dotAll: true)
          .allMatches(manifeste())
          .toList();
      expect(exportees, hasLength(1));
      expect(exportees.single.group(1), 'activity');
    });

    test('captures d\'écran bloquées (FLAG_SECURE — VULN-H05)', () {
      final activite = Directory('android/app/src/main/kotlin')
          .listSync(recursive: true)
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('MainActivity.kt'))
          .readAsStringSync();
      expect(activite, contains('WindowManager.LayoutParams.FLAG_SECURE'));
    });

    test('sauvegarde Android désactivée (jetons hors des sauvegardes cloud / adb)', () {
      final application = RegExp(r'<application[^>]*>', dotAll: true).firstMatch(manifeste())!.group(0)!;
      expect(application, contains('android:allowBackup="false"'),
          reason: 'Sans allowBackup="false", les préférences et le stockage sécurisé partent dans '
              'la sauvegarde Google / adb backup (sign le désactive).');
    });

    test('release : obfuscation et réduction activées (VULN-C02)', () {
      final gradle = lire('android/app/build.gradle.kts');
      final release = RegExp(r'release\s*\{.*?isShrinkResources\s*=\s*true', dotAll: true);
      expect(gradle, contains('isMinifyEnabled = true'));
      expect(gradle, matches(release));
    });

    test('release : refuse de signer avec la clé de debug sans demande explicite', () {
      final gradle = lire('android/app/build.gradle.kts');
      expect(gradle, contains('throw GradleException'));
      expect(gradle, contains('SIGNATURE_DEBUG'));
    });
  });

  group('iOS — App Transport Security', () {
    test('aucune exception HTTP globale', () {
      final plist = lire('ios/Runner/Info.plist');
      final ats = RegExp(r'<key>NSAppTransportSecurity</key>\s*<dict>(.*?)</dict>', dotAll: true)
              .firstMatch(plist)
              ?.group(1) ??
          '';
      expect(ats, isNot(matches(RegExp(r'NSAllowsArbitraryLoads</key>\s*<true/>'))));
      expect(ats, isNot(matches(RegExp(r'NSAllowsArbitraryLoadsInWebContent</key>\s*<true/>'))));
      expect(ats, isNot(contains('NSExceptionAllowsInsecureHTTPLoads')));
    });
  });

  group('Secrets', () {
    test('keystore et mots de passe de signature ignorés par git (BLK-06)', () {
      final gitignore = lire('.gitignore');
      for (final motif in ['android/key.properties', '*.jks', '*.keystore', '.env', 'dart_defines.local.json']) {
        expect(gitignore, contains(motif), reason: '$motif doit rester dans .gitignore');
      }
    });

    test('aucun secret versionné', () async {
      final res = await Process.run('git', ['ls-files']);
      if (res.exitCode != 0) return; // hors dépôt git (archive) : rien à vérifier
      final fichiers = (res.stdout as String).split('\n');
      final interdits = RegExp(r'(key\.properties|\.jks|\.keystore|\.p12|\.p8|\.mobileprovision|(^|/)\.env)$');
      expect(fichiers.where(interdits.hasMatch), isEmpty);
    });
  });
}
