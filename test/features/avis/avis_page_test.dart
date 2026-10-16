import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastification/toastification.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/theme/app_theme.dart';
import 'package:yobante_colis/features/avis/presentation/pages/avis_page.dart';

import '../../faux_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();

  String jwtValide() {
    String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    return '${b64({'alg': 'HS256'})}.${b64({'sub': 'u1', 'exp': 9999999999})}.signature';
  }

  final mesAvis = <Map<String, dynamic>>[];
  final aEvaluer = <Map<String, dynamic>>[];

  setUp(() async {
    await env.preparer();
    await initializeDateFormatting('fr_FR');
    Environnement.stockage.valeurs['jwt_token'] = jwtValide();
    mesAvis.clear();
    aEvaluer
      ..clear()
      ..add({'id': 'c1', 'reference': 'YC-0001', 'statut': 'livre', 'role': 'reception', 'correspondant': 'Awa Diop'});
    env.backend.routes[Env.clientAvisAEvaluer] = (_) => ok({'colis': aEvaluer});
    env.backend.routes[Env.publicAvis] = (_) => ok({
      'synthese': {'total': 0, 'noteMoyenne': 0, 'repartition': []},
      'avis': [],
      'pagination': {'totalPages': 1},
    });
    env.backend.routes[Env.clientAvis] = (o) {
      if (o.method == 'POST') {
        final d = o.data as Map;
        mesAvis.add({
          'id': 'a1',
          'note': d['note'],
          'colisId': d['colisId'],
          'colis': {'reference': 'YC-0001'},
          'statut': 'en_attente',
          'createdAt': '2026-10-16T08:00:00Z',
        });
        return (201, {'success': true, 'message': 'Merci pour votre avis : il sera publié après vérification.'});
      }
      return ok({'avis': mesAvis});
    };
  });

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(theme: AppTheme.light(), home: const AvisPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes avis'));
    await tester.pumpAndSettle();
  }

  testWidgets('dépôt d\'un avis sur un colis reçu : envoyé, puis visible dans « Mes avis »', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Donner mon avis'));
    await tester.pumpAndSettle();
    expect(find.text('Colis reçu de Awa Diop'), findsOneWidget);
    await tester.tap(find.text('YC-0001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Note : 4 sur 5'));
    await tester.pump();
    await tester.tap(find.text('Publier mon avis'));
    await tester.pumpAndSettle();

    final depots = env.backend.requetes.where((r) => r.path == Env.clientAvis && r.method == 'POST');
    expect(depots, hasLength(1));
    expect((depots.single.data as Map)['colisId'], 'c1');
    expect(find.text('Publier mon avis'), findsNothing);
    expect(find.text('En attente de vérification'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('sans expédition livrée : aucun formulaire, explication affichée', (tester) async {
    aEvaluer.clear();
    await ouvrir(tester);
    await tester.tap(find.text('Donner mon avis'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune expédition à évaluer'), findsOneWidget);
    expect(find.text('Publier mon avis'), findsNothing);
  });

  testWidgets('sans note : message visible au-dessus de la feuille', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Donner mon avis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YC-0001'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publier mon avis'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Choisissez une note de 1 à 5 étoiles.').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
