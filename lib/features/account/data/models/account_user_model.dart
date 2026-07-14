import '../../domain/entities/account_user.dart';

class AccountUserModel extends AccountUser {
  const AccountUserModel({
    required super.id, super.nom, super.prenom, super.email,
    super.telephone, super.role, super.avatarUrl, super.isActive,
  });

  factory AccountUserModel.fromJson(Map<String, dynamic> json) => AccountUserModel(
        id: json['id']?.toString() ?? '',
        nom: json['nom'] as String?,
        prenom: json['prenom'] as String?,
        email: json['email'] as String?,
        telephone: json['telephone'] as String?,
        role: json['role'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        isActive: json['isActive'] as bool?,
      );
}
