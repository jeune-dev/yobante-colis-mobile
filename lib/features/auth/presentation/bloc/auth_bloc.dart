import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/fcm_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/compteur_notifications.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<VerificationEmailRequested>(_onVerificationEmail);
    on<ResetAuthState>((_, emit) => emit(AuthInitial()));
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.login(event.identifiant, event.motDePasse);
    await result.fold(
      (f) async => emit(AuthFailure(
        message: f.errorMessage,
        emailNonConfirme: f is EmailNonConfirmeFailure,
        email: f is EmailNonConfirmeFailure ? f.email : null,
      )),
      (user) => _connecte(user, emit),
    );
  }

  /// Le code confirmé ouvre la session : même suite qu'une connexion réussie.
  Future<void> _onVerificationEmail(VerificationEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.verifierEmail(event.email, event.code);
    await result.fold(
      (f) async => emit(AuthFailure(message: f.errorMessage)),
      (user) => _connecte(user, emit),
    );
  }

  Future<void> _connecte(User user, Emitter<AuthState> emit) async {
    // La langue du compte s'applique avant d'afficher l'accueil
    await LangueApp.instance.apresConnexion(user.langue);
    emit(AuthSuccess(user: user));
    FcmService.uploadToken().catchError((_) {});
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.register(
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      motDePasse: event.motDePasse,
      telephone: event.telephone,
      pays: event.pays,
      villeId: event.villeId,
      adresse: event.adresse,
      typeCompte: event.typeCompte,
      raisonSociale: event.raisonSociale,
      numeroIdentificationFiscale: event.numeroIdentificationFiscale,
      numeroTvaIntracom: event.numeroTvaIntracom,
      codePostal: event.codePostal,
      codeParrainage: event.codeParrainage,
    );
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (message) => emit(RegisterSuccess(message: message)),
    );
  }

  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.forgotPassword(event.email);
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (message) => emit(ForgotPasswordSuccess(message: message)),
    );
  }

  Future<void> _onResetPassword(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(event.email, event.otpRecu, event.newPassword);
    result.fold(
      (f) => emit(AuthFailure(message: f.errorMessage)),
      (message) => emit(ResetPasswordSuccess(message: message)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    CompteurNotifications.instance.arreter();
    emit(AuthLoading());
    // La session locale est toujours effacée (voir AuthRepositoryImpl.logout) :
    // l'utilisateur repart sur l'accueil en invité, même hors ligne.
    await authRepository.logout();
    emit(LogoutSuccess(ouvrirConnexion: event.ouvrirConnexion));
    emit(AuthInitial());
  }
}
