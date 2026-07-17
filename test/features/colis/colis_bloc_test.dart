import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/core/errors/failure.dart';
import 'package:yobnate_colis/features/colis/domain/entities/colis.dart';
import 'package:yobnate_colis/features/colis/domain/repositories/colis_repository.dart';
import 'package:yobnate_colis/features/colis/domain/usecases/colis_usecases.dart';
import 'package:yobnate_colis/features/colis/presentation/bloc/colis_bloc.dart';
import 'package:yobnate_colis/features/colis/presentation/bloc/colis_event.dart';
import 'package:yobnate_colis/features/colis/presentation/bloc/colis_state.dart';

// ── Faux dépôt ────────────────────────────────────────────────────────────────

class _FakeColisRepository extends Fake implements ColisRepository {
  Either<Failure, Map<String, dynamic>>? getColisResult;
  Either<Failure, Colis>? getDetailResult;
  Either<Failure, Colis>? annulerResult;
  Either<Failure, List<SuiviColis>>? suiviResult;

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColis({
    String? statut,
    int page = 1,
    int limit = 20,
  }) async =>
      getColisResult!;

  @override
  Future<Either<Failure, Colis>> getColisDetail(String id) async =>
      getDetailResult!;

  @override
  Future<Either<Failure, Colis>> annulerColis(String id,
          {String? motif}) async =>
      annulerResult!;

  @override
  Future<Either<Failure, List<SuiviColis>>> getSuiviColis(String id) async =>
      suiviResult!;

  @override
  Future<Either<Failure, Map<String, dynamic>>> creerColis({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) async =>
      const Right({'colis': null, 'facture': null});
}

// ── Données de test ───────────────────────────────────────────────────────────

final _kColis = Colis(
  id: 'c1',
  reference: 'YOB-001',
  expediteurNom: 'Diallo',
  expediteurTelephone: '771234567',
  villeDepartId: 'v1',
  destinataireNom: 'Koné',
  destinataireTelephone: '779876543',
  villeArriveeId: 'v2',
  adresseLivraison: 'Rue 10, Dakar',
  typeColis: 'standard',
  poids: 2.5,
  statut: 'en_attente',
  photos: [],
  createdAt: DateTime(2025, 1, 15),
);

// ── Helper ────────────────────────────────────────────────────────────────────

ColisBloc _buildBloc(_FakeColisRepository repo) => ColisBloc(
      getColis: GetColis(repo),
      getColisDetail: GetColisDetail(repo),
      creerColis: CreerColis(repo),
      getSuiviColis: GetSuiviColis(repo),
      annulerColis: AnnulerColis(repo),
    );

Future<List<ColisState>> _collectStates(
    ColisBloc bloc, ColisEvent event) async {
  final states = <ColisState>[];
  final sub = bloc.stream.listen(states.add);
  bloc.add(event);
  await Future.delayed(const Duration(milliseconds: 50));
  await sub.cancel();
  return states;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeColisRepository fakeRepo;

  setUp(() => fakeRepo = _FakeColisRepository());

  group('ColisBloc — LoadColis', () {
    test('succès sans page suivante → ColisListLoaded(hasMore: false)',
        () async {
      fakeRepo.getColisResult = Right({
        'colis': [_kColis],
        'pagination': {'page': 1, 'totalPages': 1},
      });
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColis());

      expect(states[0], isA<ColisLoading>());
      final loaded = states[1] as ColisListLoaded;
      expect(loaded.colis.length, 1);
      expect(loaded.hasMore, false);
      expect(loaded.currentPage, 1);
      await bloc.close();
    });

    test('succès avec pages restantes → hasMore: true', () async {
      fakeRepo.getColisResult = Right({
        'colis': [_kColis],
        'pagination': {'page': 1, 'totalPages': 3},
      });
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColis());

      expect((states[1] as ColisListLoaded).hasMore, true);
      await bloc.close();
    });

    test('succès via hasNextPage: true → hasMore: true', () async {
      fakeRepo.getColisResult = Right({
        'colis': [_kColis],
        'pagination': {'hasNextPage': true},
      });
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColis());

      expect((states[1] as ColisListLoaded).hasMore, true);
      await bloc.close();
    });

    test('échec → [ColisLoading, ColisFailure]', () async {
      fakeRepo.getColisResult = Left(const ServerFailure('Erreur réseau'));
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColis());

      expect(states[0], isA<ColisLoading>());
      expect((states[1] as ColisFailure).message, 'Erreur réseau');
      await bloc.close();
    });

    test('filtre par statut est transmis au dépôt', () async {
      String? capturedStatut;
      fakeRepo.getColisResult = Right({'colis': <dynamic>[], 'pagination': null});
      // Override pour capturer le paramètre
      final bloc = ColisBloc(
        getColis: GetColis(_FakeColisRepositoryWithCapture(
          onGetColis: (statut, page) {
            capturedStatut = statut;
            return Right({'colis': <dynamic>[], 'pagination': null});
          },
        )),
        getColisDetail: GetColisDetail(fakeRepo),
        creerColis: CreerColis(fakeRepo),
        getSuiviColis: GetSuiviColis(fakeRepo),
        annulerColis: AnnulerColis(fakeRepo),
      );

      await _collectStates(bloc, const LoadColis(statut: 'en_attente'));

      expect(capturedStatut, 'en_attente');
      await bloc.close();
    });
  });

  group('ColisBloc — LoadMoreColis', () {
    test('accumule les items de la page suivante', () async {
      // Page 1
      fakeRepo.getColisResult = Right({
        'colis': [_kColis],
        'pagination': {'page': 1, 'totalPages': 3},
      });
      final bloc = _buildBloc(fakeRepo);
      bloc.add(const LoadColis());
      await Future.delayed(const Duration(milliseconds: 50));

      // Page 2
      fakeRepo.getColisResult = Right({
        'colis': [_kColis],
        'pagination': {'page': 2, 'totalPages': 3},
      });
      final states = await _collectStates(bloc, const LoadMoreColis(page: 2));

      final loaded = states[0] as ColisListLoaded;
      expect(loaded.colis.length, 2);
      expect(loaded.currentPage, 2);
      expect(loaded.hasMore, true);
      await bloc.close();
    });

    test('ignoré si l\'état courant n\'est pas ColisListLoaded', () async {
      final bloc = _buildBloc(fakeRepo);
      // ColisInitial → LoadMoreColis ignoré
      final states = await _collectStates(bloc, const LoadMoreColis(page: 2));
      expect(states, isEmpty);
      await bloc.close();
    });
  });

  group('ColisBloc — LoadColisDetail', () {
    test('succès → [ColisLoading, ColisDetailLoaded]', () async {
      fakeRepo.getDetailResult = Right(_kColis);
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColisDetail('c1'));

      expect(states[0], isA<ColisLoading>());
      expect((states[1] as ColisDetailLoaded).colis.id, 'c1');
      await bloc.close();
    });

    test('échec → [ColisLoading, ColisFailure]', () async {
      fakeRepo.getDetailResult = Left(const ServerFailure('Colis introuvable'));
      final bloc = _buildBloc(fakeRepo);

      final states = await _collectStates(bloc, const LoadColisDetail('c1'));

      expect((states[1] as ColisFailure).message, 'Colis introuvable');
      await bloc.close();
    });
  });

  group('ColisBloc — AnnulerColisRequested', () {
    test('succès → [ColisLoading, ColisAnnule]', () async {
      fakeRepo.annulerResult = Right(_kColis);
      final bloc = _buildBloc(fakeRepo);

      final states =
          await _collectStates(bloc, AnnulerColisRequested('c1'));

      expect(states[0], isA<ColisLoading>());
      expect(states[1], isA<ColisAnnule>());
      await bloc.close();
    });
  });

  group('ColisBloc — ResetColisState', () {
    test('remet l\'état à ColisInitial depuis n\'importe quel état', () async {
      // On met d'abord le bloc en ColisFailure via un vrai chargement raté
      fakeRepo.getColisResult = Left(const ServerFailure('err'));
      final bloc = _buildBloc(fakeRepo);
      bloc.add(const LoadColis());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ColisFailure>());

      final states = await _collectStates(bloc, ResetColisState());

      expect(states[0], isA<ColisInitial>());
      await bloc.close();
    });
  });
}

// ── Repo avec capture pour tester les paramètres ──────────────────────────────

class _FakeColisRepositoryWithCapture extends Fake
    implements ColisRepository {
  final Either<Failure, Map<String, dynamic>> Function(String?, int) onGetColis;
  _FakeColisRepositoryWithCapture({required this.onGetColis});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColis({
    String? statut,
    int page = 1,
    int limit = 20,
  }) async =>
      onGetColis(statut, page);

  @override
  Future<Either<Failure, Colis>> getColisDetail(String id) async =>
      Left(const ServerFailure(''));

  @override
  Future<Either<Failure, Colis>> annulerColis(String id,
          {String? motif}) async =>
      Left(const ServerFailure(''));

  @override
  Future<Either<Failure, List<SuiviColis>>> getSuiviColis(String id) async =>
      Left(const ServerFailure(''));

  @override
  Future<Either<Failure, Map<String, dynamic>>> creerColis({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) async =>
      Left(const ServerFailure(''));
}
