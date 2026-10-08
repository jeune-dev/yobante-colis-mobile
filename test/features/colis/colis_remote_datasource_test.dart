import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/errors/exceptions.dart';
import 'package:yobante_colis/features/colis/data/datasources/colis_remote_datasource.dart';
import 'package:yobante_colis/features/colis/data/models/colis_model.dart';
import 'package:yobante_colis/features/colis/domain/entities/demande_expedition.dart';
import 'package:yobante_colis/features/colis/domain/entities/filtres_colis.dart';

// ── Faux backend : enregistre la requête et renvoie une réponse préparée ─────

class _FakeAdapter implements HttpClientAdapter {
  int statut = 200;
  Object? corps;
  RequestOptions? derniere;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    derniere = options;
    return ResponseBody.fromString(jsonEncode(corps), statut, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _colisJson = {'id': 'c1', 'reference': 'YBC-1', 'statut': 'en_attente'};

void main() {
  late _FakeAdapter backend;
  late ColisRemoteDataSourceImpl ds;

  setUp(() {
    backend = _FakeAdapter();
    ds = ColisRemoteDataSourceImpl(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = backend);
  });

  group('lectures', () {
    test('getColis : filtres, statut et pagination en paramètres, colis convertis', () async {
      backend.corps = {
        'success': true,
        'data': {
          'colis': [_colisJson],
          'pagination': {'totalPages': 4, 'currentPage': 2},
        },
      };

      final res = await ds.getColis(
        statut: 'en_transit',
        filtres: const FiltresColis(reference: 'YBC', enCours: true),
        page: 2,
        limit: 10,
      );

      expect(backend.derniere!.path, '/client/colis');
      expect(backend.derniere!.queryParameters, {
        'reference': 'YBC',
        'enCours': 'true',
        'page': 2,
        'limit': 10,
        'statut': 'en_transit',
      });
      expect(res['colis'], isA<List<ColisModel>>());
      expect((res['colis'] as List).single.reference, 'YBC-1');
      expect(res['pagination'], {'totalPages': 4, 'currentPage': 2});
    });

    test('getColisRecus : seuls les filtres de période sont envoyés', () async {
      backend.corps = {
        'data': {'colis': [], 'pagination': null},
      };
      await ds.getColisRecus(filtres: FiltresColis(reference: 'X', dateDebut: DateTime(2026, 5, 1)));
      expect(backend.derniere!.path, '/client/colis/recus');
      expect(backend.derniere!.queryParameters, {'dateDebut': '2026-05-01', 'page': 1, 'limit': 20});
    });

    test('getColisDetail', () async {
      backend.corps = {
        'data': {'colis': _colisJson},
      };
      final c = await ds.getColisDetail('c1');
      expect(backend.derniere!.path, '/client/colis/c1');
      expect(c.id, 'c1');
    });

    test('getSuiviColis lit l\'historique', () async {
      backend.corps = {
        'data': {
          'historique': [
            {'statut': 'en_attente', 'libelle': 'Enregistré', 'date': '2026-09-01T00:00:00Z'},
            {'statut': 'en_transit', 'libelle': 'En route', 'date': '2026-09-02T00:00:00Z'},
          ],
        },
      };
      final suivi = await ds.getSuiviColis('c1');
      expect(backend.derniere!.path, '/client/colis/c1/suivi');
      expect(suivi.map((e) => e.libelle), ['Enregistré', 'En route']);
    });
  });

  group('actions', () {
    test('creerColis : multipart, résultat avec facture et lien de paiement', () async {
      backend.corps = {
        'message': 'Expédition enregistrée',
        'data': {
          'colis': _colisJson,
          'facture': {'reference': 'FAC-9'},
          'lienPaiement': 'https://pay/9',
          'adresseReception': {'ville': 'Paris'},
        },
      };
      final res = await ds.creerColis(
        const DemandeExpedition(categorie: 'documents', villeDepartId: 'a', villeArriveeId: 'b'),
      );
      expect(backend.derniere!.method, 'POST');
      expect(backend.derniere!.path, '/client/colis');
      expect(backend.derniere!.data, isA<FormData>());
      final champs = Map.fromEntries((backend.derniere!.data as FormData).fields);
      expect(champs['categorie'], 'documents');
      expect(res.message, 'Expédition enregistrée');
      expect(res.factureReference, 'FAC-9');
      expect(res.lienPaiement, 'https://pay/9');
      expect(res.adresseReception, {'ville': 'Paris'});
    });

    test('annulerColis envoie le motif en PATCH', () async {
      backend.corps = {
        'message': 'Expédition annulée',
        'data': {'colis': _colisJson},
      };
      final res = await ds.annulerColis('c1', motif: 'Doublon');
      expect(backend.derniere!.method, 'PATCH');
      expect(backend.derniere!.path, '/client/colis/c1/annuler');
      expect(backend.derniere!.data, {'motif': 'Doublon'});
      expect(res.message, 'Expédition annulée');
      expect(res.valeur.id, 'c1');
    });

    test('annulerColis sans motif envoie un corps vide', () async {
      backend.corps = {
        'data': {'colis': _colisJson},
      };
      await ds.annulerColis('c1');
      expect(backend.derniere!.data, isEmpty);
    });

    test('accepter et refuser la proposition', () async {
      backend.corps = {
        'message': 'OK',
        'data': {'colis': _colisJson, 'lienPaiement': 'https://pay/1'},
      };
      final accepte = await ds.accepterProposition('c1');
      expect(backend.derniere!.path, '/client/colis/c1/proposition/accepter');
      expect(accepte.lienPaiement, 'https://pay/1');

      await ds.refuserProposition('c1');
      expect(backend.derniere!.path, '/client/colis/c1/proposition/refuser');
      expect(backend.derniere!.data, isEmpty);

      await ds.refuserProposition('c1', motif: 'Trop cher');
      expect(backend.derniere!.data, {'motif': 'Trop cher'});
    });

    test('modifierColis envoie les champs en PATCH', () async {
      backend.corps = {
        'data': {'colis': _colisJson},
      };
      await ds.modifierColis('c1', {'destinataireNom': 'Fatou'});
      expect(backend.derniere!.method, 'PATCH');
      expect(backend.derniere!.path, '/client/colis/c1');
      expect(backend.derniere!.data, {'destinataireNom': 'Fatou'});
    });

    test('abonnerSuivi nettoie la destination', () async {
      backend.corps = {'message': 'Inscription enregistrée'};
      final msg = await ds.abonnerSuivi('c1', canal: 'email', destination: '  a@b.sn ');
      expect(backend.derniere!.path, '/client/colis/c1/abonnement-suivi');
      expect(backend.derniere!.data, {'canal': 'email', 'destination': 'a@b.sn', 'profil': 'destinataire'});
      expect(msg, 'Inscription enregistrée');
    });
  });

  group('erreurs', () {
    test('détails de validation du backend → ServerException lisible', () async {
      backend
        ..statut = 400
        ..corps = {
          'message': 'Données invalides',
          'details': ['Téléphone invalide', 'Nom requis'],
        };
      await expectLater(
        ds.getColisDetail('c1'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Téléphone invalide\nNom requis')),
      );
    });

    test('le code d\'erreur du backend est conservé', () async {
      backend
        ..statut = 403
        ..corps = {'message': 'Modification impossible', 'code': 'COLIS_NON_MODIFIABLE'};
      await expectLater(
        ds.modifierColis('c1', const {}),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'Modification impossible')
            .having((e) => e.code, 'code', 'COLIS_NON_MODIFIABLE')),
      );
    });

    test('réponse sans message : message par défaut de l\'opération', () async {
      backend
        ..statut = 400
        ..corps = {};
      await expectLater(
        ds.accepterProposition('c1'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Impossible d\'accepter la proposition')),
      );
    });
  });
}
