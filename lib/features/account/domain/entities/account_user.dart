import 'package:equatable/equatable.dart';
import '../../../../core/i18n/langue.dart';

class AccountUser extends Equatable {
  final String id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? role;
  final String? avatarUrl;
  final bool? isActive;

  const AccountUser({
    required this.id, this.nom, this.prenom, this.email,
    this.telephone, this.role, this.avatarUrl, this.isActive,
  });

  String get fullName {
    final p = prenom?.trim() ?? '';
    final n = nom?.trim() ?? '';
    if (p.isNotEmpty && n.isNotEmpty) return '$p $n';
    return p.isNotEmpty ? p : (n.isNotEmpty ? n : tr('Utilisateur'));
  }

  @override
  List<Object?> get props => [id, email, role];
}
