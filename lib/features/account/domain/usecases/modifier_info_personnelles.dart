import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/account_user.dart';
import '../repositories/account_repository.dart';
import '../../../../core/types/avec_message.dart';

class ModifierInfoPersonnelles {
  final AccountRepository repository;
  ModifierInfoPersonnelles(this.repository);

  Future<Either<Failure, AvecMessage<AccountUser>>> call({String? nom, String? prenom, String? telephone}) =>
      repository.modifierInfoPersonnelles(nom: nom, prenom: prenom, telephone: telephone);
}
