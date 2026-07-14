import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/ville.dart';
import '../repositories/villes_repository.dart';

class GetVilles {
  final VillesRepository repo;
  GetVilles(this.repo);
  Future<Either<Failure, List<Ville>>> call() => repo.getVilles();
}
