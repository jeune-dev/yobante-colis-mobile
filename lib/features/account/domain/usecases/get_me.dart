import 'package:dartz/dartz.dart';
import 'package:yobnate_colis/core/errors/failure.dart';
import '../entities/account_user.dart';
import '../repositories/account_repository.dart';

class GetMe {
  final AccountRepository repository;
  GetMe(this.repository);

  Future<Either<Failure, AccountUser>> call() => repository.getMe();
}

