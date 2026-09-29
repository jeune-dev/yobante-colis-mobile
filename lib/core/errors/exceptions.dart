class ServerException implements Exception {
  final String message;
  const ServerException({required this.message});
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
