import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/colis.dart';
import '../entities/demande_expedition.dart';

abstract class ColisRepository {
  Future<Either<Failure, Map<String, dynamic>>> getColis({String? statut, int page = 1, int limit = 20});
  Future<Either<Failure, Map<String, dynamic>>> getColisRecus({String? statut, int page = 1, int limit = 20});
  Future<Either<Failure, Colis>> getColisDetail(String id);

  Future<Either<Failure, ResultatDeclaration>> creerColis(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  });

  Future<Either<Failure, List<SuiviEvenement>>> getSuiviColis(String id);
  Future<Either<Failure, Colis>> annulerColis(String id, {String? motif});

  Future<Either<Failure, ResultatDeclaration>> accepterProposition(String id);
  Future<Either<Failure, Colis>> refuserProposition(String id, {String? motif});
  Future<Either<Failure, Colis>> modifierColis(String id, Map<String, dynamic> champs);
}
