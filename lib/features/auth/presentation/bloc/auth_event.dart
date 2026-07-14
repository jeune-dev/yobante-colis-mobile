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
  const RegisterRequested({
    required this.nom, required this.prenom, required this.email,
    required this.motDePasse, required this.telephone,
  });
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}
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
