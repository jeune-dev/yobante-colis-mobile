import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yobante_colis/core/services/compteur_notifications.dart';
import 'package:yobante_colis/core/services/token_service.dart';
import 'package:yobante_colis/features/notifications/domain/repositories/notifications_repository.dart';

class _FauxToken implements TokenService {
  bool connecte = true;
  @override
  Future<bool> get isAuthenticated async => connecte;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FauxDepot implements NotificationsRepository {
  int nonLues = 0;
  @override
  Future<Either<Never, int>> getNonLuesCount() async => Right(nonLues);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final compteur = CompteurNotifications.instance;
  late _FauxToken token;
  late _FauxDepot depot;

  setUp(() {
    token = _FauxToken();
    depot = _FauxDepot();
    GetIt.instance
      ..registerSingleton<TokenService>(token)
      ..registerSingleton<NotificationsRepository>(depot);
  });

  tearDown(() async {
    compteur.arreter();
    await GetIt.instance.reset();
  });

  test('démarrage : valeur du serveur', () async {
    depot.nonLues = 3;
    compteur.demarrer();
    await Future<void>.delayed(Duration.zero);
    expect(compteur.value, 3);
  });

  test('notification push reçue : +1, puis recalage sur le serveur', () async {
    compteur.definir(2);
    depot.nonLues = 3;
    compteur.nouvelleNotification();
    expect(compteur.value, 3);
    await Future<void>.delayed(Duration.zero);
    expect(compteur.value, 3);
  });

  test('notification ouverte : -1, jamais en dessous de zéro', () {
    compteur.definir(1);
    compteur.notificationLue();
    expect(compteur.value, 0);
    compteur.notificationLue();
    expect(compteur.value, 0);
  });

  test('tout marquer comme lu : zéro', () {
    compteur.definir(7);
    compteur.toutesLues();
    expect(compteur.value, 0);
  });

  test('non connecté : zéro, sans appel au serveur', () async {
    token.connecte = false;
    depot.nonLues = 5;
    await compteur.rafraichir();
    expect(compteur.value, 0);
  });

  test('déconnexion : arrêt et remise à zéro', () {
    compteur.definir(4);
    compteur.arreter();
    expect(compteur.value, 0);
  });
}
