import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/utils/pagination.dart';

/// Backend paginé simulé : [totalPages] pages de deux éléments.
class _BackendPagine implements HttpClientAdapter {
  final int totalPages;
  final pagesDemandees = <int>[];
  final requetes = <Map<String, dynamic>>[];
  _BackendPagine(this.totalPages);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final page = options.queryParameters['page'] as int;
    pagesDemandees.add(page);
    requetes.add(options.queryParameters);
    final corps = {
      'data': {
        'factures': [
          {'id': 'p$page-a'},
          {'id': 'p$page-b'},
        ],
        'pagination': {'totalPages': totalPages, 'currentPage': page},
      },
    };
    return ResponseBody.fromString(jsonEncode(corps), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Dio dio(HttpClientAdapter a) => Dio()..httpClientAdapter = a;

  test('charge toutes les pages et concatène les éléments', () async {
    final backend = _BackendPagine(3);
    final res = await chargerToutesLesPages(dio(backend), '/client/factures', 'factures', parametres: {'statut': 'payee'});

    expect(backend.pagesDemandees, [1, 2, 3]);
    expect(res.map((e) => e['id']), ['p1-a', 'p1-b', 'p2-a', 'p2-b', 'p3-a', 'p3-b']);
    expect(backend.requetes.first, {'statut': 'payee', 'page': 1, 'limit': kTaillePageMax});
  });

  test('s\'arrête à maxPages', () async {
    final backend = _BackendPagine(50);
    final res = await chargerToutesLesPages(dio(backend), '/x', 'factures', maxPages: 2);
    expect(backend.pagesDemandees, [1, 2]);
    expect(res, hasLength(4));
  });

  test('une seule page sans pagination ni liste', () async {
    final adapter = _ReponseFixe({'data': {}});
    final res = await chargerToutesLesPages(dio(adapter), '/x', 'factures');
    expect(res, isEmpty);
    expect(adapter.appels, 1);
  });
}

class _ReponseFixe implements HttpClientAdapter {
  final Object corps;
  int appels = 0;
  _ReponseFixe(this.corps);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    appels++;
    return ResponseBody.fromString(jsonEncode(corps), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
