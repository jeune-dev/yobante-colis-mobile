import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../../features/account/domain/entities/account_user.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import 'demo_data.dart';
import '../types/avec_message.dart';

class DemoAccountRepository implements AccountRepository {
  @override
  Future<Either<Failure, AccountUser>> getMe() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return Right(DemoData.account);
  }

  @override
  Future<Either<Failure, AvecMessage<AccountUser>>> modifierInfoPersonnelles({
    String? nom,
    String? prenom,
    String? telephone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final actuel = DemoData.account;
    DemoData.account = AccountUser(
      id: actuel.id,
      nom: nom ?? actuel.nom,
      prenom: prenom ?? actuel.prenom,
      email: actuel.email,
      telephone: telephone ?? actuel.telephone,
      role: actuel.role,
      avatarUrl: actuel.avatarUrl,
      isActive: actuel.isActive,
    );
    return Right((valeur: DemoData.account, message: 'Profil mis à jour.'));
  }

  @override
  Future<Either<Failure, AvecMessage<AccountUser>>> uploadAvatar(String filePath) async {
    // Aucun stockage réel en mode démo — on confirme visuellement l'action
    // sans dépendre du réseau (avatar par initiales conservé).
    await Future.delayed(const Duration(milliseconds: 500));
    return Right((valeur: DemoData.account, message: 'Photo de profil mise à jour.'));
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Right('Mot de passe modifié avec succès.');
  }
}
