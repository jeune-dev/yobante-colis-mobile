import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../../features/villes/domain/entities/ville.dart';
import '../../features/villes/domain/repositories/villes_repository.dart';
import 'demo_data.dart';

class DemoVillesRepository implements VillesRepository {
  @override
  Future<Either<Failure, List<Ville>>> getVilles() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Right(List<Ville>.from(DemoData.villes));
  }
}
