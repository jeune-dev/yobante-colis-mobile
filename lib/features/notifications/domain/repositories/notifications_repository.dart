import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/notification_app.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationApp>>> getNotifications({int page, int limit});
  Future<Either<Failure, int>> getNonLuesCount();
  Future<Either<Failure, void>> marquerLue(String id);
  Future<Either<Failure, void>> marquerToutesLues();
  Future<Either<Failure, void>> supprimer(String id);
}
