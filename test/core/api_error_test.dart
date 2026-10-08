import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/errors/api_error.dart';
import 'package:yobante_colis/core/errors/exceptions.dart';
import 'package:yobante_colis/core/errors/failure.dart';

DioException _erreur({int? statut, Object? data, DioExceptionType type = DioExceptionType.badResponse}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: type,
    response: statut == null ? null : Response(requestOptions: req, statusCode: statut, data: data),
  );
}

/// Traduction des réponses d'erreur du backend en messages affichables.
void main() {
  group('messageErreur', () {
    test('les détails de validation priment sur le message générique', () {
      final e = _erreur(statut: 400, data: {
        'message': 'Données invalides',
        'details': ['Poids requis', 'Ville inconnue'],
      });
      expect(messageErreur(e), 'Poids requis\nVille inconnue');
    });

    test('message du backend affiché tel quel', () {
      expect(messageErreur(_erreur(statut: 409, data: {'message': 'Déjà annulé'})), 'Déjà annulé');
    });

    test('erreur 500 : référence de requête ajoutée', () {
      final e = _erreur(statut: 500, data: {'message': 'Erreur interne', 'requestId': 'req-42'});
      expect(messageErreur(e), 'Erreur interne (réf. req-42)');
    });

    test('la référence n\'est ajoutée qu\'aux 500', () {
      final e = _erreur(statut: 503, data: {'message': 'Maintenance', 'requestId': 'req-42'});
      expect(messageErreur(e), 'Maintenance');
    });

    test('corps JSON reçu en texte : décodé', () {
      final e = _erreur(statut: 404, data: '  {"message":"Introuvable","code":"NON_TROUVE"}');
      expect(messageErreur(e), 'Introuvable');
      expect(codeErreur(e), 'NON_TROUVE');
    });

    test('502/503/504 sans corps : service indisponible', () {
      for (final s in [502, 503, 504]) {
        expect(messageErreur(_erreur(statut: s, data: '<html>')), contains('temporairement indisponible'));
      }
    });

    test('pas de connexion', () {
      for (final t in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(messageErreur(_erreur(type: t)), isNotEmpty);
      }
    });

    test('repli sur le message par défaut, puis générique', () {
      expect(messageErreur(_erreur(statut: 400, data: {}), 'Échec'), 'Échec');
      expect(messageErreur(_erreur(statut: 400)), 'Une erreur est survenue');
    });
  });

  group('codeErreur', () {
    test('code présent, absent ou vide', () {
      expect(codeErreur(_erreur(statut: 403, data: {'code': 'EMAIL_NON_CONFIRME'})), 'EMAIL_NON_CONFIRME');
      expect(codeErreur(_erreur(statut: 403, data: {'code': ''})), isNull);
      expect(codeErreur(_erreur(statut: 403, data: 'texte')), isNull);
      expect(codeErreur(_erreur(type: DioExceptionType.connectionError)), isNull);
    });
  });

  group('messageApi', () {
    Response res(Object? data) => Response(requestOptions: RequestOptions(), data: data);

    test('message de la réponse, sinon défaut', () {
      expect(messageApi(res({'message': 'Colis créé'})), 'Colis créé');
      expect(messageApi(res({'message': ''}), 'défaut'), 'défaut');
      expect(messageApi(res(null), 'défaut'), 'défaut');
    });
  });

  group('appelApi', () {
    test('renvoie le résultat en cas de succès', () async {
      expect(await appelApi(() async => 42), 42);
    });

    test('DioException → ServerException avec message et code', () async {
      await expectLater(
        appelApi(() async => throw _erreur(statut: 403, data: {'message': 'Interdit', 'code': 'ROLE'})),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'Interdit')
            .having((e) => e.code, 'code', 'ROLE')),
      );
    });

    test('les autres exceptions ne sont pas masquées', () async {
      await expectLater(appelApi(() async => throw const FormatException('x')), throwsFormatException);
    });
  });

  group('Failure', () {
    test('égalité sur le type et le message', () {
      expect(const ServerFailure('a'), const ServerFailure('a'));
      expect(const ServerFailure('a').hashCode, const ServerFailure('a').hashCode);
      expect(const ServerFailure('a'), isNot(const ServerFailure('b')));
      expect(const ServerFailure('a'), isNot(const CacheFailure('a')));
      expect(const EmailNonConfirmeFailure('a'), isA<ServerFailure>());
    });

    test('toString lisible', () {
      expect(const ServerFailure('Oups').toString(), 'ServerFailure(Oups)');
    });
  });
}
