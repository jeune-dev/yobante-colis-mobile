import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/ville.dart';

abstract class VillesRepository {
  Future<Either<Failure, List<Ville>>> getVilles();
}
