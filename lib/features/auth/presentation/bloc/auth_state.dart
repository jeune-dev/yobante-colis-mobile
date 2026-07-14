import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess({required this.user});
  @override List<Object?> get props => [user];
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess();
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure({required this.message});
  @override List<Object?> get props => [message];
}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  const ForgotPasswordSuccess({required this.message});
  @override List<Object?> get props => [message];
}

class ResetPasswordSuccess extends AuthState {}
