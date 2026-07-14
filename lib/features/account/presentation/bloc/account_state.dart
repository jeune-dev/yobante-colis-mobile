import 'package:yobnate_colis/features/account/domain/entities/account_user.dart';

abstract class AccountState {}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountLoaded extends AccountState {
  final AccountUser user;
  AccountLoaded(this.user);
}

class AccountSuccess extends AccountState {
  final AccountUser user;
  final String message;
  AccountSuccess({required this.user, this.message = 'Profil mis à jour'});
}

class PasswordChanged extends AccountState {
  final String message;
  PasswordChanged({this.message = 'Mot de passe modifié avec succès'});
}

class AccountError extends AccountState {
  final String message;
  AccountError(this.message);
}
