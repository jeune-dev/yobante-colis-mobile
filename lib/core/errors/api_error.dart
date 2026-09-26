import 'dart:convert';
import 'package:dio/dio.dart';
import 'exceptions.dart';

/// Message d'erreur lisible à partir d'une réponse du backend.
///
/// Les erreurs de validation arrivent sous la forme
/// `{ message: 'Données invalides', details: ['…', '…'] }` : le détail est plus
/// utile au client que le message générique, il est donc privilégié.
String messageErreur(DioException e, [String defaut = 'Une erreur est survenue']) {
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
    if (message is String && message.isNotEmpty) return message;
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Connexion au serveur impossible. Vérifiez votre accès internet.';
  }
  return defaut;
}

/// Exécute un appel réseau en traduisant les erreurs Dio en [ServerException].
Future<T> appelApi<T>(Future<T> Function() appel, [String defaut = 'Une erreur est survenue']) async {
  try {
    return await appel();
  } on DioException catch (e) {
    throw ServerException(message: messageErreur(e, defaut));
  }
}
