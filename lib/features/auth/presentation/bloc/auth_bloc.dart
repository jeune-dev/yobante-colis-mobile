import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<ResetAuthState>((_, emit) => emit(AuthInitial()));
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.login(event.identifiant, event.motDePasse);
    await result.fold(
      (f) async => emit(AuthFailure(message: f.errorMessage)),
      (user) async {
        emit(AuthSuccess(user: user));
        FcmService.uploadToken().catchError((_) {});
      },
    );
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.register(
      nom: event.nom, prenom: event.prenom, email: event.email,
      motDePasse: event.motDePasse, telephone: event.telephone,
    );
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (_) => emit(const RegisterSuccess()),
    );
  }

  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.forgotPassword(event.email);
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (_) => emit(const ForgotPasswordSuccess(message: 'Un code a été envoyé à votre email.')),
    );
  }

  Future<void> _onResetPassword(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(event.email, event.otpRecu, event.newPassword);
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> _onLogout(LogoutRequested _, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await revokeRefreshToken(sl());
      await sl<TokenService>().clearToken();
      await sl<FlutterSecureStorage>().delete(key: 'user_id');
      await sl<FlutterSecureStorage>().delete(key: 'user_role');
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Erreur lors de la déconnexion : $e'));
    }
  }
}
