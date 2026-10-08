import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

/// Session fermée et jetons effacés : l'app repart sur l'accueil en invité.
class LogoutSuccess extends AuthState {
  final bool ouvrirConnexion;
  const LogoutSuccess({this.ouvrirConnexion = false});
  @override List<Object?> get props => [ouvrirConnexion];
}

class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess({required this.user});
  @override List<Object?> get props => [user];
}

class RegisterSuccess extends AuthState {
  final String message;
  const RegisterSuccess({this.message = ''});
  @override List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;

  /// Connexion refusée tant que l'adresse email n'est pas confirmée.
  final bool emailNonConfirme;

  /// Adresse du compte à confirmer (renvoyée par le backend avec le refus).
  final String? email;
  const AuthFailure({required this.message, this.emailNonConfirme = false, this.email});
  @override List<Object?> get props => [message, emailNonConfirme, email];
}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  const ForgotPasswordSuccess({required this.message});
  @override List<Object?> get props => [message];
}

class ResetPasswordSuccess extends AuthState {
  final String message;
  const ResetPasswordSuccess({this.message = ''});
  @override List<Object?> get props => [message];
}
