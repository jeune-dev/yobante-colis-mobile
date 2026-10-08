import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/errors/exceptions.dart';
import 'package:yobante_colis/core/utils/fichier_upload.dart';

/// Tests de sécurité — fichiers envoyés au backend (photos de colis, pièces
/// justificatives). Le type est déduit du CONTENU réel du fichier, jamais de
/// son extension : un exécutable renommé en .jpg est refusé avant l'envoi.
void main() {
  late Directory dossier;

  setUp(() => dossier = Directory.systemTemp.createTempSync('upload_test'));
  tearDown(() => dossier.deleteSync(recursive: true));

  String fichier(String nom, List<int> octets) {
    final f = File('${dossier.path}/$nom')..writeAsBytesSync(octets);
    return f.path;
  }

  const jpeg = [0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46];
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  const pdf = [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37];

  Matcher refuse(String extrait) =>
      throwsA(isA<ServerException>().having((e) => e.message, 'message', contains(extrait)));

  test('JPEG et PNG acceptés, type déclaré d\'après le contenu', () async {
    final j = await fichierMultipart(fichier('photo.jpg', jpeg));
    expect(j.contentType.toString(), 'image/jpeg');

    final p = await fichierMultipart(fichier('capture.png', png));
    expect(p.contentType.toString(), 'image/png');
  });

  test('exécutable renommé en .jpg refusé', () async {
    final elf = fichier('photo.jpg', [0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0]);
    await expectLater(fichierMultipart(elf), refuse('Format non accepté'));

    final script = fichier('photo.png', '<?php system(\$_GET["c"]); ?>'.codeUnits);
    await expectLater(fichierMultipart(script), refuse('Format non accepté'));
  });

  test('PDF refusé sauf quand il est explicitement accepté', () async {
    final chemin = fichier('justificatif.pdf', pdf);
    await expectLater(fichierMultipart(chemin), refuse('Format non accepté'));

    final ok = await fichierMultipart(chemin, pdfAccepte: true);
    expect(ok.contentType.toString(), 'application/pdf');
  });

  test('fichier vide refusé', () async {
    await expectLater(fichierMultipart(fichier('vide.jpg', [])), refuse('Format non accepté'));
  });

  test('extension réécrite d\'après le contenu (pas de double extension)', () async {
    final f = await fichierMultipart(fichier('facture.php.jpg', jpeg));
    expect(f.filename, 'facture.jpg');

    final deguise = await fichierMultipart(fichier('image.pdf', png));
    expect(deguise.filename, 'image.png');
  });

  test('taille maximale respectée', () async {
    final gros = fichier('gros.jpg', [...jpeg, ...List.filled(kTailleMaxFichier, 0)]);
    await expectLater(fichierMultipart(gros), refuse('trop volumineux'));

    // Les photos de colis ont une limite plus large
    final photo = await fichierMultipart(gros, tailleMax: kTailleMaxPhotoColis);
    expect(photo.contentType.toString(), 'image/jpeg');
  });
}
