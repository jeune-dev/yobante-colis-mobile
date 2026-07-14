import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final String? accessToken;
  final String? refreshToken;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.accessToken,
    this.refreshToken,
  });

  String get fullName => '$prenom $nom';

  @override
  List<Object?> get props => [id, email, role];
}
