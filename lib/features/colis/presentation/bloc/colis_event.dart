import 'package:equatable/equatable.dart';
import '../../domain/entities/demande_expedition.dart';
import '../../domain/entities/filtres_colis.dart';

abstract class ColisEvent extends Equatable {
  const ColisEvent();
  @override
  List<Object?> get props => [];
}

class LoadColis extends ColisEvent {
  final String? statut;
  final FiltresColis filtres;
  final int page;
  const LoadColis({this.statut, this.filtres = const FiltresColis(), this.page = 1});
  @override
  List<Object?> get props => [statut, filtres, page];
}

class LoadColisRecus extends ColisEvent {
  final String? statut;
  final FiltresColis filtres;
  final int page;
  const LoadColisRecus({this.statut, this.filtres = const FiltresColis(), this.page = 1});
  @override
  List<Object?> get props => [statut, filtres, page];
}

class LoadColisDetail extends ColisEvent {
  final String id;
  const LoadColisDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadSuiviColis extends ColisEvent {
  final String id;
  const LoadSuiviColis(this.id);
  @override
  List<Object?> get props => [id];
}

class CreerColisRequested extends ColisEvent {
  final DemandeExpedition demande;
  final List<String> photosPaths;
  const CreerColisRequested(this.demande, {this.photosPaths = const []});

  @override
  List<Object?> get props => [demande, photosPaths];
}

class AccepterPropositionRequested extends ColisEvent {
  final String id;
  const AccepterPropositionRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class RefuserPropositionRequested extends ColisEvent {
  final String id;
  final String? motif;
  const RefuserPropositionRequested(this.id, {this.motif});
  @override
  List<Object?> get props => [id, motif];
}

class ModifierColisRequested extends ColisEvent {
  final String id;
  final Map<String, dynamic> champs;
  const ModifierColisRequested(this.id, this.champs);
  @override
  List<Object?> get props => [id, champs];
}

class AnnulerColisRequested extends ColisEvent {
  final String id;
  final String? motif;
  const AnnulerColisRequested(this.id, {this.motif});
  @override
  List<Object?> get props => [id];
}

class LoadMoreColis extends ColisEvent {
  final String? statut;
  final FiltresColis filtres;
  final int page;
  const LoadMoreColis({this.statut, this.filtres = const FiltresColis(), required this.page});
  @override
  List<Object?> get props => [statut, filtres, page];
}

class LoadMoreColisRecus extends ColisEvent {
  final String? statut;
  final FiltresColis filtres;
  final int page;
  const LoadMoreColisRecus({this.statut, this.filtres = const FiltresColis(), required this.page});
  @override
  List<Object?> get props => [statut, filtres, page];
}

class ResetColisState extends ColisEvent {}
