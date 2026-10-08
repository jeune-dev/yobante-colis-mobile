import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests de sécurité — journaux (VULN-H02 de sign : aucun print(), aucune
/// donnée sensible dans les logs).
///
/// Les journaux Android (logcat) sont lisibles par les outils de debug et
/// remontés dans les rapports de crash : un jeton ou un mot de passe écrit
/// dans la console fuit hors de l'application.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  Iterable<(String, int, String)> lignes() sync* {
    for (final f in sources) {
      final contenu = f.readAsLinesSync();
      for (var i = 0; i < contenu.length; i++) {
        final l = contenu[i].trim();
        if (l.startsWith('//')) continue;
        yield (f.path, i + 1, l);
      }
    }
  }

  test('aucun print() dans le code de l\'application', () {
    final fautifs = [
      for (final (fichier, n, l) in lignes())
        if (RegExp(r'(^|[^\w.])print\(').hasMatch(l)) '$fichier:$n  $l',
    ];
    expect(fautifs, isEmpty, reason: 'Utiliser debugPrint sous kDebugMode, sans donnée sensible');
  });

  test('les journaux ne contiennent ni jeton, ni mot de passe, ni en-têtes, ni corps', () {
    final sensible = RegExp(
      r'token|password|motDePasse|mot_de_passe|Authorization|headers|\.data\b|refresh|\bcode(Retrait|Verification)?\b',
      caseSensitive: false,
    );
    final fautifs = [
      for (final (fichier, n, l) in lignes())
        if (RegExp(r'debugPrint\(|log\(').hasMatch(l) && sensible.hasMatch(l)) '$fichier:$n  $l',
    ];
    expect(fautifs, isEmpty);
  });

  test('les traces réseau sont réservées au debug et ne journalisent que le chemin', () {
    final intercepteur = File('lib/injection_container.dart').readAsLinesSync().where((l) => l.contains('debugPrint'));
    expect(intercepteur, isNotEmpty);
    for (final l in intercepteur) {
      expect(l, contains('if (kDebugMode)'), reason: l.trim());
      expect(l, isNot(contains('.uri')), reason: 'L\'URI complète porterait les paramètres (email, référence…)');
      expect(l, isNot(contains('queryParameters')), reason: l.trim());
    }
  });
}
