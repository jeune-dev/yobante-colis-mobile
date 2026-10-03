import 'package:dartz/dartz.dart';
import 'package:yobante_colis/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class ChangePassword {
  final AccountRepository repository;
  ChangePassword(this.repository);

  Future<Either<Failure, String>> call({
    required String oldPassword,
    required String newPassword,
  }) =>
      repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
}

