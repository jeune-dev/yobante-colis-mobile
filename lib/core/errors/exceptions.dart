class ServerException implements Exception {
  final String message;

  /// Code stable renvoyé par le backend (ex. TELEPHONE_NON_VERIFIE) : le message
  /// est traduit selon la langue, le code ne change jamais.
  final String? code;
  const ServerException({required this.message, this.code});
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

/// Connexion refusée (403) parce que l'adresse email n'est pas encore confirmée.
class EmailNonConfirmeException extends ServerException {
  const EmailNonConfirmeException({required super.message});
}
