import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
    required super.role,
    super.avatarUrl,
    super.isActive,
    super.accessToken,
    super.refreshToken,
    super.langue,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final u = json['utilisateur'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: u['id']?.toString() ?? '',
      nom: u['nom'] as String? ?? '',
      prenom: u['prenom'] as String? ?? '',
      email: u['email'] as String? ?? '',
      telephone: u['telephone'] as String? ?? '',
      role: u['role'] as String? ?? 'client',
      avatarUrl: u['avatarUrl'] as String?,
      isActive: u['isActive'] as bool? ?? true,
      langue: u['langue'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String? refreshToken;

  AuthResponseModel({required this.user, required this.accessToken, this.refreshToken});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String?;
    final userJson = data['utilisateur'] as Map<String, dynamic>? ?? {};
    return AuthResponseModel(
      user: UserModel.fromJson({...userJson, 'accessToken': accessToken, 'refreshToken': refreshToken}),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
