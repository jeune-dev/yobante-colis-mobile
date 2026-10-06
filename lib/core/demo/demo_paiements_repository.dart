import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../../features/paiements/domain/entities/facture_colis.dart';
import '../../features/paiements/domain/repositories/paiements_repository.dart';
import 'demo_data.dart';

class DemoPaiementsRepository implements PaiementsRepository {
  @override
  Future<Either<Failure, List<FactureColis>>> getFactures({String? statut, bool impayees = false}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(DemoData.factures
        .where((f) => statut == null || f.statut == statut)
        .where((f) => !impayees || const ['en_attente', 'partiellement_payee'].contains(f.statut))
        .toList());
  }

  @override
  Future<Either<Failure, FactureColis>> getFactureDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final f in DemoData.factures) {
      if (f.id == id) return Right(f);
    }
    return const Left(ServerFailure('Facture introuvable'));
  }
}
