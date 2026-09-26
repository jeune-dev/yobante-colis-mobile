import 'package:equatable/equatable.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/demande_expedition.dart';

abstract class ColisState extends Equatable {
  const ColisState();
  @override
  List<Object?> get props => [];
}

class ColisInitial extends ColisState {}

class ColisLoading extends ColisState {}

class ColisUploadProgress extends ColisState {
  final double progress;
  const ColisUploadProgress(this.progress);
  @override
  List<Object?> get props => [progress];
}

class ColisListLoaded extends ColisState {
  final List<Colis> colis;
  final Map<String, dynamic>? pagination;
  final int currentPage;
  final bool hasMore;

  const ColisListLoaded({
    required this.colis,
    this.pagination,
    this.currentPage = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [colis, currentPage];
}

/// Même forme que [ColisListLoaded], pour les colis reçus (destinataire).
class ColisRecusLoaded extends ColisState {
  final List<Colis> colis;
  final Map<String, dynamic>? pagination;
  final int currentPage;
  final bool hasMore;

  const ColisRecusLoaded({
    required this.colis,
    this.pagination,
    this.currentPage = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [colis, currentPage];
}

class ColisDetailLoaded extends ColisState {
  final Colis colis;
  const ColisDetailLoaded(this.colis);
  @override
  List<Object?> get props => [colis];
}

class SuiviColisLoaded extends ColisState {
  final List<SuiviEvenement> historique;
  const SuiviColisLoaded(this.historique);
  @override
  List<Object?> get props => [historique];
}

class ColisCreated extends ColisState {
  final ResultatDeclaration resultat;
  const ColisCreated(this.resultat);
  Colis get colis => resultat.colis;
  @override
  List<Object?> get props => [resultat.colis];
}

/// Proposition tarifaire acceptée : la facture et son lien de paiement sont émis.
class PropositionAcceptee extends ColisState {
  final ResultatDeclaration resultat;
  const PropositionAcceptee(this.resultat);
  @override
  List<Object?> get props => [resultat.colis];
}

class PropositionRefusee extends ColisState {
  final Colis colis;
  const PropositionRefusee(this.colis);
  @override
  List<Object?> get props => [colis];
}

class ColisModifie extends ColisState {
  final Colis colis;
  const ColisModifie(this.colis);
  @override
  List<Object?> get props => [colis];
}

class ColisAnnule extends ColisState {
  final Colis colis;
  const ColisAnnule(this.colis);
  @override
  List<Object?> get props => [colis];
}

class ColisFailure extends ColisState {
  final String message;
  const ColisFailure(this.message);
  @override
  List<Object?> get props => [message];
}
