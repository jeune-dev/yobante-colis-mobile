import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifiant;
  final String motDePasse;
  const LoginRequested({required this.identifiant, required this.motDePasse});
  @override
  List<Object?> get props => [identifiant];
}

class RegisterRequested extends AuthEvent {
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String telephone;
  final String pays;
  final String? villeId;
  final String? adresse;
  final String typeCompte;
  final String? raisonSociale;
  final String? numeroIdentificationFiscale;
  final String? numeroTvaIntracom;
  final String? codePostal;
  final String? codeParrainage;
  const RegisterRequested({
    required this.nom, required this.prenom, required this.email,
    required this.motDePasse, required this.telephone,
    this.pays = 'SN',
    this.villeId,
    this.adresse,
    this.typeCompte = 'particulier',
    this.raisonSociale,
    this.numeroIdentificationFiscale,
    this.numeroTvaIntracom,
    this.codePostal,
    this.codeParrainage,
  });
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {
  /// Ouvre l'écran de connexion par-dessus l'accueil une fois déconnecté
  /// (session expirée, mot de passe changé…).
  final bool ouvrirConnexion;
  const LogoutRequested({this.ouvrirConnexion = false});
  @override
  List<Object?> get props => [ouvrirConnexion];
}
class ResetAuthState extends AuthEvent {}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String otpRecu;
  final String newPassword;
  const ResetPasswordRequested({required this.email, required this.otpRecu, required this.newPassword});
  @override
  List<Object?> get props => [email];
}

/// Saisie du code de confirmation reçu par email après l'inscription.
class VerificationEmailRequested extends AuthEvent {
  final String email;
  final String code;
  const VerificationEmailRequested({required this.email, required this.code});
  @override
  List<Object?> get props => [email, code];
}
