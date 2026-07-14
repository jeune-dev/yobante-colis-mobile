abstract class AccountEvent {}

class LoadMe extends AccountEvent {}

class ModifierInfoPersonnellesEvent extends AccountEvent {
  final String? nom;
  final String? prenom;
  final String? telephone;
  ModifierInfoPersonnellesEvent({this.nom, this.prenom, this.telephone});
}

class UploadAvatarEvent extends AccountEvent {
  final String filePath;
  UploadAvatarEvent(this.filePath);
}

class ChangePasswordEvent extends AccountEvent {
  final String oldPassword;
  final String newPassword;
  ChangePasswordEvent({required this.oldPassword, required this.newPassword});
}

class ResetAccountState extends AccountEvent {}
