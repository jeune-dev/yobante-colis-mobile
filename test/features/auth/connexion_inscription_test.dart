import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:yobante_colis/core/config/env.dart';
import 'package:yobante_colis/core/widgets/primary_button.dart';
import 'package:yobante_colis/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yobante_colis/features/auth/presentation/pages/login_page.dart';
import 'package:yobante_colis/features/auth/presentation/pages/register_page.dart';
import 'package:yobante_colis/features/auth/presentation/pages/verification_email_page.dart';
import 'package:yobante_colis/injection_container.dart';

import '../../faux_backend.dart';

/// Connexion et inscription : contrôles de saisie, requête envoyée au serveur,
/// session enregistrée et écran suivant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Environnement();

  setUp(() async {
    await env.preparer();
    env.backend.routes[Env.publicVilles] = (_) => ok({'villes': []});
  });

  Future<void> monter(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1170, 5000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        // Bloc neuf à chaque test : aucun état hérité du test précédent
        create: (_) => AuthBloc(authRepository: sl()),
        // Même enveloppe que main.dart : les notifications (toasts) s'affichent par elle
        child: ToastificationWrapper(
          child: MaterialApp(
            home: page,
            onGenerateRoute: (r) => MaterialPageRoute(builder: (_) => Scaffold(body: Text('route ${r.name}'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Laisse se fermer les notifications (toasts) avant la fin du test.
  Future<void> attendreToasts(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Finder champ(String indication) => find.widgetWithText(TextFormField, indication);

  group('connexion', () {
    Future<void> seConnecter(WidgetTester tester, String identifiant, String motDePasse) async {
      await tester.enterText(champ('Votre email ou numéro'), identifiant);
      await tester.enterText(champ('Votre mot de passe'), motDePasse);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('champs vides : messages de saisie, aucun appel au serveur', (tester) async {
      await monter(tester, const LoginPage());
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(find.text('Email ou téléphone requis'), findsOneWidget);
      expect(find.text('Mot de passe requis'), findsOneWidget);
      expect(env.backend.vers(Env.authLogin), isEmpty);
    });

    testWidgets('numéro saisi sans indicatif : envoyé au format international', (tester) async {
      env.backend.routes[Env.authLogin] = (_) => (401, {'message': 'Identifiants incorrects'});
      await monter(tester, const LoginPage());
      await seConnecter(tester, '77 123 45 67', 'Secret#2026');

      final envoi = env.backend.vers(Env.authLogin).single.data as Map<String, dynamic>;
      expect(envoi['identifiant'], '+221771234567');
      // Réponse du serveur puis apparition de la notification (fermée au bout de 3,8 s)
      for (var i = 0; i < 20 && find.text('Identifiants incorrects').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Identifiants incorrects'), findsOneWidget);
      expect(Environnement.stockage.valeurs, isEmpty, reason: 'aucune session ouverte après un refus');
      await attendreToasts(tester);
    });

    testWidgets('connexion réussie : jetons et rôle enregistrés, ouverture de l\'espace client', (tester) async {
      env.backend.routes[Env.authLogin] = (_) => ok({
        'accessToken': 'jeton-acces',
        'refreshToken': 'jeton-renouvellement',
        'utilisateur': {'id': 'u1', 'nom': 'DIOP', 'prenom': 'Awa', 'email': 'awa@exemple.sn', 'role': 'client'},
      });
      await monter(tester, const LoginPage());
      await seConnecter(tester, 'awa@exemple.sn', 'Secret#2026');
      await tester.pumpAndSettle();

      expect(Environnement.stockage.valeurs['jwt_token'], 'jeton-acces');
      expect(Environnement.stockage.valeurs['refresh_token'], 'jeton-renouvellement');
      expect(Environnement.stockage.valeurs['user_role'], 'client');
      expect(find.text('route /client'), findsOneWidget);
    });
  });

  group('inscription', () {
    Future<void> remplir(
      WidgetTester tester, {
      String telephone = '773071639',
      String confirmation = 'Secret#2026',
    }) async {
      await tester.enterText(champ('Ex: Mamadou'), 'awa');
      await tester.enterText(champ('Ex: Diallo'), 'diop');
      await tester.enterText(champ('exemple@gmail.com'), 'awa@exemple.sn');
      await tester.enterText(champ('Ex: 77 123 45 67'), telephone);
      await tester.enterText(champ('Votre mot de passe'), 'Secret#2026');
      await tester.enterText(champ('Saisissez-le à nouveau'), confirmation);
      await tester.pump();
    }

    Future<void> valider(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('formulaire vide : aucun appel au serveur', (tester) async {
      await monter(tester, const RegisterPage());
      await valider(tester);

      expect(find.text('Indiquez votre prénom'), findsOneWidget);
      expect(find.text('Numéro requis'), findsOneWidget);
      expect(env.backend.vers(Env.authRegister), isEmpty);
    });

    testWidgets('confirmation différente du mot de passe : refus avant envoi', (tester) async {
      await monter(tester, const RegisterPage());
      await remplir(tester, confirmation: 'Autre#2026');
      await valider(tester);

      expect(env.backend.vers(Env.authRegister), isEmpty);
    });

    testWidgets('inscription : numéro composé avec l\'indicatif, nom normalisé, écran de confirmation ouvert', (
      tester,
    ) async {
      env.backend.routes[Env.authRegister] = (_) => (201, {'success': true, 'message': 'Compte créé', 'data': {}});
      await monter(tester, const RegisterPage());
      await remplir(tester);
      await valider(tester);
      await tester.pumpAndSettle();

      final envoi = env.backend.vers(Env.authRegister).single.data as Map<String, dynamic>;
      expect(envoi['telephone'], '+221773071639');
      expect(envoi['nom'], 'DIOP');
      expect(envoi['prenom'], 'Awa');
      expect(envoi['email'], 'awa@exemple.sn');
      expect(envoi['pays'], 'SN');
      expect(find.byType(VerificationEmailPage), findsOneWidget);
    });

    testWidgets('numéro français avec le 0 national : envoyé en +33', (tester) async {
      env.backend.routes[Env.authRegister] = (_) => (201, {'success': true, 'message': 'Compte créé', 'data': {}});
      await monter(tester, const RegisterPage());
      // Choix de la France dans le sélecteur d'indicatif
      await tester.tap(find.text('+221'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('France').last);
      await tester.pumpAndSettle();
      await remplir(tester, telephone: '06 12 34 56 78');
      await valider(tester);
      await tester.pumpAndSettle();

      final envoi = env.backend.vers(Env.authRegister).single.data as Map<String, dynamic>;
      expect(envoi['telephone'], '+33612345678');
    });
  });

  testWidgets('inscription invalide : la page remonte jusqu\'au premier champ en erreur', (tester) async {
    // Écran de téléphone réel : le formulaire dépasse et doit défiler
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(authRepository: sl()),
        child: const ToastificationWrapper(child: MaterialApp(home: RegisterPage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Prénom')).top, lessThan(0), reason: 'le haut du formulaire est hors écran');

    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    final erreur = tester.getRect(find.text('Indiquez votre prénom'));
    expect(erreur.top, greaterThanOrEqualTo(0));
    expect(erreur.bottom, lessThanOrEqualTo(844), reason: 'le champ en erreur est ramené à l\'écran');
    expect(env.backend.vers(Env.authRegister), isEmpty);
  });
}
