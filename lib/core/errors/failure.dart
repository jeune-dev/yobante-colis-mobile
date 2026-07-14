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
  const ServerFailure(super.errorMessage);
}

class CacheFailure extends Failure {
  const CacheFailure(super.errorMessage);
}
