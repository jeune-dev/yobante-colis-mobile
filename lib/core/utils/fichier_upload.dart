import 'dart:io';
import 'package:dio/dio.dart';
import '../errors/exceptions.dart';
import '../i18n/langue.dart';

/// Préparation des fichiers envoyés en multipart.
///
/// Le backend n'accepte que des images JPEG ou PNG et des PDF, contrôlés sur le
/// type déclaré ET sur le contenu réel du fichier (signature binaire), dans la
/// limite de 5 Mo par fichier (10 Mo pour les photos de colis). Sans type
/// déclaré, Dio envoie `application/octet-stream` : le fichier est refusé.
///
/// Les contrôles sont donc faits ici, avant l'envoi, avec un message clair.

const int kTailleMaxFichier = 5 * 1024 * 1024;
const int kTailleMaxPhotoColis = 10 * 1024 * 1024;

/// Type réel d'un fichier d'après ses premiers octets, ou `null` s'il n'est pas accepté.
({DioMediaType type, String extension})? _typeReel(List<int> o) {
  bool debut(List<int> sig) => o.length >= sig.length && Iterable.generate(sig.length).every((i) => o[i] == sig[i]);
  if (debut([0xff, 0xd8, 0xff])) return (type: DioMediaType('image', 'jpeg'), extension: 'jpg');
  if (debut([0x89, 0x50, 0x4e, 0x47])) return (type: DioMediaType('image', 'png'), extension: 'png');
  if (debut([0x25, 0x50, 0x44, 0x46])) return (type: DioMediaType('application', 'pdf'), extension: 'pdf');
  return null;
}

/// Fichier prêt à joindre au formulaire ; lève une [ServerException] lisible si
/// le format ou la taille ne conviennent pas.
Future<MultipartFile> fichierMultipart(
  String chemin, {
  bool pdfAccepte = false,
  int tailleMax = kTailleMaxFichier,
}) async {
  final fichier = File(chemin);
  final taille = await fichier.length();
  if (taille > tailleMax) {
    throw ServerException(
      message: tr('Fichier trop volumineux (maximum ${tailleMax ~/ (1024 * 1024)} Mo).'),
    );
  }

  final entete = await fichier.openRead(0, 8).fold<List<int>>([], (acc, bloc) => acc..addAll(bloc));
  final reel = _typeReel(entete);
  if (reel == null || (!pdfAccepte && reel.extension == 'pdf')) {
    throw ServerException(
      message: pdfAccepte
          ? tr('Format non accepté : choisissez une image JPEG, PNG ou un PDF.')
          : tr('Format non accepté : choisissez une image JPEG ou PNG.'),
    );
  }

  final nom = chemin.split(Platform.pathSeparator).last.split('.').first;
  return MultipartFile.fromFile(chemin, filename: '$nom.${reel.extension}', contentType: reel.type);
}
