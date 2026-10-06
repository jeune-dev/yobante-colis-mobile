import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/facture_colis.dart';

abstract class PaiementsRepository {
  Future<Either<Failure, List<FactureColis>>> getFactures({String? statut, bool impayees = false});
  Future<Either<Failure, FactureColis>> getFactureDetail(String id);
}
