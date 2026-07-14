import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/colis.dart';

abstract class ColisRepository {
  Future<Either<Failure, Map<String, dynamic>>> getColis({
    String? statut,
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, Colis>> getColisDetail(String id);
  Future<Either<Failure, Map<String, dynamic>>> creerColis({
    required String expediteurNom,
    required String expediteurTelephone,
    required String villeDepartId,
    required String destinataireNom,
    required String destinataireTelephone,
    required String villeArriveeId,
    required String adresseLivraison,
    required double poids,
    String? description,
    String typeColis = 'standard',
    double? valeurDeclaree,
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  });
  Future<Either<Failure, List<SuiviColis>>> getSuiviColis(String id);
  Future<Either<Failure, Colis>> annulerColis(String id, {String? motif});
}
