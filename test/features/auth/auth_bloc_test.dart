import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/core/errors/failure.dart';
import 'package:yobnate_colis/features/auth/domain/entities/user.dart';
import 'package:yobnate_colis/features/auth/domain/repositories/auth_repository.dart';
import 'package:yobnate_colis/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yobnate_colis/features/auth/presentation/bloc/auth_event.dart';
import 'package:yobnate_colis/features/auth/presentation/bloc/auth_state.dart';

// ── Faux dépôt ────────────────────────────────────────────────────────────────

class _FakeAuthRepository extends Fake implements AuthRepository {
  Either<Failure, User>? loginResult;
  Either<Failure, void>? registerResult;
  Either<Failure, void>? forgotResult;
  Either<Failure, void>? resetResult;
  bool logoutCalled = false;

  @override
  Future<Either<Failure, User>> login(String email, String password) async =>
      loginResult!;

  @override
  Future<Either<Failure, void>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
    String pays = 'SN',
    String? villeId,
    String? adresse,
    String typeCompte = 'particulier',
    String? raisonSociale,
    String? numeroIdentificationFiscale,
    String? numeroTvaIntracom,
    String? codePostal,
    String? codeParrainage,
  }) async =>
      registerResult!;

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async =>
      forgotResult!;

  @override
  Future<Either<Failure, void>> resetPassword(
          String email, String code, String newPassword) async =>
      resetResult!;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

// ── Données de test ───────────────────────────────────────────────────────────

const _kUser = User(
  id: 'u1',
  nom: 'Diallo',
  prenom: 'Moussa',
  email: 'moussa@example.com',
  telephone: '771234567',
  role: 'client',
);

// ── Helper ────────────────────────────────────────────────────────────────────

Future<List<AuthState>> _collectStates(
    AuthBloc bloc, AuthEvent event) async {
  final states = <AuthState>[];
  final sub = bloc.stream.listen(states.add);
  bloc.add(event);
  await Future.delayed(const Duration(milliseconds: 50));
  await sub.cancel();
  return states;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeAuthRepository fakeRepo;

  setUp(() => fakeRepo = _FakeAuthRepository());

  group('AuthBloc — LoginRequested', () {
    test('succès → [AuthLoading, AuthSuccess]', () async {
      fakeRepo.loginResult = const Right(_kUser);
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(
        bloc,
        const LoginRequested(
            identifiant: 'moussa@example.com', motDePasse: 'password123'),
      );

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthSuccess>());
      expect((states[1] as AuthSuccess).user.id, 'u1');
      await bloc.close();
    });

    test('échec → [AuthLoading, AuthFailure] avec message', () async {
      fakeRepo.loginResult = Left(const ServerFailure('Identifiants invalides'));
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(
        bloc,
        const LoginRequested(identifiant: 'x@x.com', motDePasse: 'wrong'),
      );

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthFailure>());
      expect((states[1] as AuthFailure).message, 'Identifiants invalides');
      await bloc.close();
    });
  });

  group('AuthBloc — RegisterRequested', () {
    test('succès → [AuthLoading, RegisterSuccess]', () async {
      fakeRepo.registerResult = const Right(null);
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(
        bloc,
        const RegisterRequested(
          nom: 'Diallo',
          prenom: 'Moussa',
          email: 'moussa@example.com',
          motDePasse: 'pass123',
          telephone: '771234567',
        ),
      );

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<RegisterSuccess>());
      await bloc.close();
    });

    test('échec → [AuthLoading, AuthFailure]', () async {
      fakeRepo.registerResult = Left(const ServerFailure('Email déjà utilisé'));
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(
        bloc,
        const RegisterRequested(
          nom: 'D',
          prenom: 'M',
          email: 'existing@example.com',
          motDePasse: 'pass',
          telephone: '77',
        ),
      );

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthFailure).message, 'Email déjà utilisé');
      await bloc.close();
    });
  });

  group('AuthBloc — LogoutRequested', () {
    test('→ [AuthLoading, AuthInitial] et appelle repo.logout()', () async {
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(bloc, LogoutRequested());

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthInitial>());
      expect(fakeRepo.logoutCalled, true);
      await bloc.close();
    });
  });

  group('AuthBloc — ForgotPasswordRequested', () {
    test('succès → [AuthLoading, ForgotPasswordSuccess]', () async {
      fakeRepo.forgotResult = const Right(null);
      final bloc = AuthBloc(authRepository: fakeRepo);

      final states = await _collectStates(
        bloc,
        const ForgotPasswordRequested(email: 'moussa@example.com'),
      );

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<ForgotPasswordSuccess>());
      await bloc.close();
    });
  });

  group('AuthBloc — ResetAuthState', () {
    test('efface l\'état d\'erreur → AuthInitial', () async {
      final bloc = AuthBloc(authRepository: fakeRepo);
      // Forcer un état d'erreur d'abord
      fakeRepo.loginResult = Left(const ServerFailure('err'));
      bloc.add(const LoginRequested(identifiant: 'x', motDePasse: 'y'));
      await Future.delayed(const Duration(milliseconds: 50));

      final states = await _collectStates(bloc, ResetAuthState());

      expect(states.last, isA<AuthInitial>());
      await bloc.close();
    });
  });
}
