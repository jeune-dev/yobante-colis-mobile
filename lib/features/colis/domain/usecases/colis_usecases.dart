import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/colis.dart';
import '../entities/demande_expedition.dart';
import '../repositories/colis_repository.dart';

class GetColis {
  final ColisRepository repo;
  GetColis(this.repo);
  Future<Either<Failure, Map<String, dynamic>>> call({String? statut, int page = 1, int limit = 20}) =>
      repo.getColis(statut: statut, page: page, limit: limit);
}

class GetColisRecus {
  final ColisRepository repo;
  GetColisRecus(this.repo);
  Future<Either<Failure, Map<String, dynamic>>> call({String? statut, int page = 1, int limit = 20}) =>
      repo.getColisRecus(statut: statut, page: page, limit: limit);
}

class GetColisDetail {
  final ColisRepository repo;
  GetColisDetail(this.repo);
  Future<Either<Failure, Colis>> call(String id) => repo.getColisDetail(id);
}

class CreerColis {
  final ColisRepository repo;
  CreerColis(this.repo);
  Future<Either<Failure, ResultatDeclaration>> call(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) =>
      repo.creerColis(demande, photosPaths: photosPaths, onSendProgress: onSendProgress);
}

class GetSuiviColis {
  final ColisRepository repo;
  GetSuiviColis(this.repo);
  Future<Either<Failure, List<SuiviEvenement>>> call(String id) => repo.getSuiviColis(id);
}

class AnnulerColis {
  final ColisRepository repo;
  AnnulerColis(this.repo);
  Future<Either<Failure, Colis>> call(String id, {String? motif}) =>
      repo.annulerColis(id, motif: motif);
}

class RepondreProposition {
  final ColisRepository repo;
  RepondreProposition(this.repo);
  Future<Either<Failure, ResultatDeclaration>> accepter(String id) => repo.accepterProposition(id);
  Future<Either<Failure, Colis>> refuser(String id, {String? motif}) =>
      repo.refuserProposition(id, motif: motif);
}

class ModifierColis {
  final ColisRepository repo;
  ModifierColis(this.repo);
  Future<Either<Failure, Colis>> call(String id, Map<String, dynamic> champs) =>
      repo.modifierColis(id, champs);
}
