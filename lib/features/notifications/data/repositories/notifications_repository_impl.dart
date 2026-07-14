import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/notification_app.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remote;
  NotificationsRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<NotificationApp>>> getNotifications({int page = 1, int limit = 20}) async {
    try { return Right(await remote.getNotifications(page: page, limit: limit)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, int>> getNonLuesCount() async {
    try { return Right(await remote.getNonLuesCount()); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, void>> marquerLue(String id) async {
    try { await remote.marquerLue(id); return const Right(null); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, void>> marquerToutesLues() async {
    try { await remote.marquerToutesLues(); return const Right(null); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }
}
