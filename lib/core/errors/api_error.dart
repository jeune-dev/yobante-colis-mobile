import 'dart:convert';
import 'package:dio/dio.dart';
import 'exceptions.dart';
import '../i18n/langue.dart';

/// Message d'erreur lisible à partir d'une réponse du backend.
///
/// Les erreurs de validation arrivent sous la forme
/// `{ message: 'Données invalides', details: ['…', '…'] }` : le détail est plus
/// utile au client que le message générique, il est donc privilégié.
String messageErreur(DioException e, [String? defaut]) {
  var data = e.response?.data;
  // Réponse lue en texte (documents HTML) : l'erreur reste un JSON à décoder
  if (data is String && data.trimLeft().startsWith('{')) {
    try {
      data = jsonDecode(data);
    } catch (_) {}
  }
  if (data is Map) {
    final details = data['details'];
    if (details is List && details.isNotEmpty) return details.map((d) => '$d').join('\n');
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      // Erreur interne (500) : la référence de la requête permet de retrouver la
      // cause exacte dans les journaux du backend. Un 503 (indisponibilité
      // temporaire, envoi de fichier refusé…) porte un message explicite du
      // backend, affiché tel quel.
      final reference = data['requestId'];
      final statut = e.response?.statusCode ?? 0;
      return statut == 500 && reference is String && reference.isNotEmpty ? '$message (réf. $reference)' : message;
    }
  }
  // 502/503/504 sans corps JSON (proxy, redémarrage de l'API)
  final statut = e.response?.statusCode ?? 0;
  if (statut == 502 || statut == 503 || statut == 504) {
    return tr('Service temporairement indisponible, réessayez dans un instant.');
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return tr('Connexion au serveur impossible. Vérifiez votre accès internet.');
  }
  return defaut ?? tr('Une erreur est survenue');
}

/// Code stable de l'erreur renvoyé par le backend (`{ code: 'EMAIL_NON_CONFIRME' }`).
String? codeErreur(DioException e) {
  var data = e.response?.data;
  if (data is String && data.trimLeft().startsWith('{')) {
    try {
      data = jsonDecode(data);
    } catch (_) {}
  }
  final code = data is Map ? data['code'] : null;
  return code is String && code.isNotEmpty ? code : null;
}

/// Message de la réponse du backend (`{ success, message, data }`), prévu pour
/// être affiché tel quel ; [defaut] ne sert que si la réponse n'en contient pas.
String messageApi(Response res, [String defaut = '']) {
  final data = res.data;
  final message = data is Map ? data['message'] : null;
  return message is String && message.isNotEmpty ? message : defaut;
}

/// Exécute un appel réseau en traduisant les erreurs Dio en [ServerException].
Future<T> appelApi<T>(Future<T> Function() appel, [String? defaut]) async {
  try {
    return await appel();
  } on DioException catch (e) {
    throw ServerException(message: messageErreur(e, defaut), code: codeErreur(e));
  }
}
