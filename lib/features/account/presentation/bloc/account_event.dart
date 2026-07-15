import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();
  @override
  List<Object?> get props => [];
}

class LoadMe extends AccountEvent {
  const LoadMe();
}

class ModifierInfoPersonnellesEvent extends AccountEvent {
  final String? nom;
  final String? prenom;
  final String? telephone;
  const ModifierInfoPersonnellesEvent({this.nom, this.prenom, this.telephone});
  @override
  List<Object?> get props => [nom, prenom, telephone];
}

class UploadAvatarEvent extends AccountEvent {
  final String filePath;
  const UploadAvatarEvent(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class ChangePasswordEvent extends AccountEvent {
  final String oldPassword;
  final String newPassword;
  const ChangePasswordEvent({required this.oldPassword, required this.newPassword});
  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class ResetAccountState extends AccountEvent {
  const ResetAccountState();
}
