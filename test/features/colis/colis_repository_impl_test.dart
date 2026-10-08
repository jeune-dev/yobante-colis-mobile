import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/errors/exceptions.dart';
import 'package:yobante_colis/core/errors/failure.dart';
import 'package:yobante_colis/core/types/avec_message.dart';
import 'package:yobante_colis/features/colis/data/datasources/colis_remote_datasource.dart';
import 'package:yobante_colis/features/colis/data/models/colis_model.dart';
import 'package:yobante_colis/features/colis/data/repositories/colis_repository_impl.dart';
import 'package:yobante_colis/features/colis/domain/entities/colis.dart';
import 'package:yobante_colis/features/colis/domain/entities/demande_expedition.dart';
import 'package:yobante_colis/features/colis/domain/entities/filtres_colis.dart';
import 'package:yobante_colis/features/colis/domain/usecases/colis_usecases.dart';

// ── Faux datasource ───────────────────────────────────────────────────────────

class _FakeColisDataSource extends Fake implements ColisRemoteDataSource {
  ServerException? erreur;
  final appels = <String, Map<String, dynamic>>{};

  static final colis = ColisModel.fromJson(const {'id': 'c1', 'reference': 'YBC-1', 'statut': 'en_attente'});

  Future<T> _repondre<T>(String nom, Map<String, dynamic> args, T valeur) async {
    appels[nom] = args;
    if (erreur != null) throw erreur!;
    return valeur;
  }

  @override
  Future<Map<String, dynamic>> getColis(
          {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20}) =>
      _repondre('getColis', {'statut': statut, 'filtres': filtres, 'page': page, 'limit': limit}, {
        'colis': [colis],
        'pagination': {'totalPages': 1},
      });

  @override
  Future<Map<String, dynamic>> getColisRecus(
          {String? statut, FiltresColis filtres = const FiltresColis(), int page = 1, int limit = 20}) =>
      _repondre('getColisRecus', {'statut': statut, 'page': page}, {'colis': <ColisModel>[]});

  @override
  Future<ColisModel> getColisDetail(String id) => _repondre('getColisDetail', {'id': id}, colis);

  @override
  Future<ResultatDeclaration> creerColis(DemandeExpedition demande,
          {List<String> photosPaths = const [], void Function(int, int)? onSendProgress}) =>
      _repondre('creerColis', {'photos': photosPaths}, ResultatDeclaration(colis: colis, message: 'Créé'));

  @override
  Future<List<SuiviEvenement>> getSuiviColis(String id) => _repondre('getSuiviColis', {'id': id}, [
        SuiviEvenement(statut: 'en_attente', libelle: 'Enregistré', date: DateTime(2026)),
      ]);

  @override
  Future<AvecMessage<ColisModel>> annulerColis(String id, {String? motif}) =>
      _repondre('annulerColis', {'id': id, 'motif': motif}, (valeur: colis, message: 'Annulé'));

  @override
  Future<ResultatDeclaration> accepterProposition(String id) => _repondre(
      'accepterProposition', {'id': id}, ResultatDeclaration(colis: colis, message: 'Accepté', lienPaiement: 'l'));

  @override
  Future<AvecMessage<ColisModel>> refuserProposition(String id, {String? motif}) =>
      _repondre('refuserProposition', {'id': id, 'motif': motif}, (valeur: colis, message: 'Refusé'));

  @override
  Future<AvecMessage<ColisModel>> modifierColis(String id, Map<String, dynamic> champs) =>
      _repondre('modifierColis', {'id': id, 'champs': champs}, (valeur: colis, message: 'Modifié'));
}

void main() {
  late _FakeColisDataSource ds;
  late ColisRepositoryImpl repo;

  setUp(() {
    ds = _FakeColisDataSource();
    repo = ColisRepositoryImpl(ds);
  });

  T droite<T>(Either<Failure, T> r) => r.fold((f) => fail('Left inattendu : $f'), (v) => v);

  group('ColisRepositoryImpl — succès', () {
    test('getColis transmet statut, filtres et pagination', () async {
      const filtres = FiltresColis(categorie: 'documents');
      final res = droite(await repo.getColis(statut: 'livre', filtres: filtres, page: 3, limit: 50));
      expect(res['colis'], hasLength(1));
      expect(ds.appels['getColis'], {'statut': 'livre', 'filtres': filtres, 'page': 3, 'limit': 50});
    });

    test('getColisRecus', () async {
      droite(await repo.getColisRecus(page: 2));
      expect(ds.appels['getColisRecus'], {'statut': null, 'page': 2});
    });

    test('getColisDetail renvoie le colis', () async {
      expect(droite(await repo.getColisDetail('c1')).reference, 'YBC-1');
      expect(ds.appels['getColisDetail'], {'id': 'c1'});
    });

    test('creerColis transmet les photos', () async {
      const demande = DemandeExpedition(categorie: 'documents', villeDepartId: 'a', villeArriveeId: 'b');
      final res = droite(await repo.creerColis(demande, photosPaths: ['/tmp/a.jpg']));
      expect(res.message, 'Créé');
      expect(ds.appels['creerColis'], {
        'photos': ['/tmp/a.jpg'],
      });
    });

    test('getSuiviColis', () async {
      expect(droite(await repo.getSuiviColis('c1')).single.libelle, 'Enregistré');
    });

    test('annulerColis transmet le motif et garde le message', () async {
      final res = droite(await repo.annulerColis('c1', motif: 'Erreur de saisie'));
      expect(res.message, 'Annulé');
      expect(ds.appels['annulerColis'], {'id': 'c1', 'motif': 'Erreur de saisie'});
    });

    test('accepter / refuser la proposition', () async {
      expect(droite(await repo.accepterProposition('c1')).lienPaiement, 'l');
      expect(droite(await repo.refuserProposition('c1', motif: 'Trop cher')).message, 'Refusé');
      expect(ds.appels['refuserProposition'], {'id': 'c1', 'motif': 'Trop cher'});
    });

    test('modifierColis transmet les champs', () async {
      droite(await repo.modifierColis('c1', {'destinataireNom': 'X'}));
      expect(ds.appels['modifierColis'], {
        'id': 'c1',
        'champs': {'destinataireNom': 'X'},
      });
    });
  });

  group('ColisRepositoryImpl — erreurs', () {
    setUp(() => ds.erreur = const ServerException(message: 'Colis introuvable', code: 'COLIS_INTROUVABLE'));

    test('ServerException → ServerFailure avec message et code', () async {
      final res = await repo.getColisDetail('x');
      expect(res, const Left<Failure, Colis>(ServerFailure('Colis introuvable')));
      final failure = res.fold((f) => f, (_) => null) as ServerFailure;
      expect(failure.code, 'COLIS_INTROUVABLE');
    });

    test('toutes les opérations convertissent l\'erreur', () async {
      const demande = DemandeExpedition(categorie: 'documents', villeDepartId: 'a', villeArriveeId: 'b');
      final resultats = <Either<Failure, dynamic>>[
        await repo.getColis(),
        await repo.getColisRecus(),
        await repo.creerColis(demande),
        await repo.getSuiviColis('x'),
        await repo.annulerColis('x'),
        await repo.accepterProposition('x'),
        await repo.refuserProposition('x'),
        await repo.modifierColis('x', const {}),
      ];
      for (final r in resultats) {
        expect(r.isLeft(), isTrue);
        r.fold((f) => expect(f.errorMessage, 'Colis introuvable'), (_) {});
      }
    });
  });

  group('Cas d\'usage — délégation au dépôt', () {
    late ColisRepositoryImpl r;
    setUp(() => r = ColisRepositoryImpl(ds));

    test('GetColis / GetColisDetail / AnnulerColis / ModifierColis', () async {
      await GetColis(r)(statut: 'en_transit', page: 2);
      expect(ds.appels['getColis']!['statut'], 'en_transit');
      expect(ds.appels['getColis']!['page'], 2);

      await GetColisDetail(r)('c9');
      expect(ds.appels['getColisDetail'], {'id': 'c9'});

      await AnnulerColis(r)('c9', motif: 'm');
      expect(ds.appels['annulerColis'], {'id': 'c9', 'motif': 'm'});

      await ModifierColis(r)('c9', {'a': 1});
      expect(ds.appels['modifierColis']!['champs'], {'a': 1});
    });

    test('RepondreProposition accepte et refuse', () async {
      final uc = RepondreProposition(r);
      await uc.accepter('c2');
      await uc.refuser('c2', motif: 'non');
      expect(ds.appels['accepterProposition'], {'id': 'c2'});
      expect(ds.appels['refuserProposition'], {'id': 'c2', 'motif': 'non'});
    });

    test('GetColisRecus / GetSuiviColis / CreerColis', () async {
      await GetColisRecus(r)(statut: 'livre');
      expect(ds.appels['getColisRecus']!['statut'], 'livre');
      await GetSuiviColis(r)('c3');
      expect(ds.appels['getSuiviColis'], {'id': 'c3'});
      await CreerColis(r)(
        const DemandeExpedition(categorie: 'documents', villeDepartId: 'a', villeArriveeId: 'b'),
        photosPaths: const ['p'],
      );
      expect(ds.appels['creerColis'], {
        'photos': ['p'],
      });
    });
  });
}
