import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/account_user.dart';
import '../../../../core/types/avec_message.dart';

abstract class AccountRepository {
  Future<Either<Failure, AccountUser>> getMe();
  // Les actions renvoient aussi le message du backend, affiché tel quel
  Future<Either<Failure, AvecMessage<AccountUser>>> modifierInfoPersonnelles({String? nom, String? prenom, String? telephone});
  Future<Either<Failure, AvecMessage<AccountUser>>> uploadAvatar(String filePath);
  Future<Either<Failure, String>> changePassword({required String oldPassword, required String newPassword});
}
