import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/account_user.dart';

abstract class AccountRepository {
  Future<Either<Failure, AccountUser>> getMe();
  Future<Either<Failure, AccountUser>> modifierInfoPersonnelles({String? nom, String? prenom, String? telephone});
  Future<Either<Failure, AccountUser>> uploadAvatar(String filePath);
  Future<Either<Failure, void>> changePassword({required String oldPassword, required String newPassword});
}
