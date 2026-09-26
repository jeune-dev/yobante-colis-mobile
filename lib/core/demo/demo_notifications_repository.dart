import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../../features/notifications/domain/entities/notification_app.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import 'demo_data.dart';

class DemoNotificationsRepository implements NotificationsRepository {
  @override
  Future<Either<Failure, List<NotificationApp>>> getNotifications({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final sorted = List<NotificationApp>.from(DemoData.notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(sorted);
  }

  @override
  Future<Either<Failure, int>> getNonLuesCount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Right(DemoData.notifications.where((n) => !n.isRead).length);
  }

  @override
  Future<Either<Failure, void>> marquerLue(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = DemoData.notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final n = DemoData.notifications[index];
      DemoData.notifications[index] = NotificationApp(
        id: n.id, titre: n.titre, message: n.message, type: n.type,
        isRead: true, lienCible: n.lienCible, createdAt: n.createdAt,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> marquerToutesLues() async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (var i = 0; i < DemoData.notifications.length; i++) {
      final n = DemoData.notifications[i];
      DemoData.notifications[i] = NotificationApp(
        id: n.id, titre: n.titre, message: n.message, type: n.type,
        isRead: true, lienCible: n.lienCible, createdAt: n.createdAt,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> supprimer(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    DemoData.notifications.removeWhere((n) => n.id == id);
    return const Right(null);
  }
}
