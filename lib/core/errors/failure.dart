abstract class Failure {
  final String errorMessage;
  const Failure(this.errorMessage);

  @override
  String toString() => '$runtimeType($errorMessage)';

  @override
  int get hashCode => Object.hash(runtimeType, errorMessage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is Failure &&
          other.errorMessage == errorMessage;
}

class ServerFailure extends Failure {
  /// Code stable de l'erreur côté backend (voir [ServerException.code]).
  final String? code;
  const ServerFailure(super.errorMessage, {this.code});
}

/// Email non confirmé : l'écran de connexion propose de renvoyer le lien.
class EmailNonConfirmeFailure extends ServerFailure {
  final String? email;
  const EmailNonConfirmeFailure(super.errorMessage, {this.email});
}

class CacheFailure extends Failure {
  const CacheFailure(super.errorMessage);
}
