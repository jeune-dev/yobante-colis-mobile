import 'package:equatable/equatable.dart';

abstract class ColisEvent extends Equatable {
  const ColisEvent();
  @override
  List<Object?> get props => [];
}

class LoadColis extends ColisEvent {
  final String? statut;
  final int page;
  const LoadColis({this.statut, this.page = 1});
  @override
  List<Object?> get props => [statut, page];
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
  final String expediteurNom;
  final String expediteurTelephone;
  final String villeDepartId;
  final String destinataireNom;
  final String destinataireTelephone;
  final String villeArriveeId;
  final String adresseLivraison;
  final double poids;
  final String? description;
  final String typeColis;
  final double? valeurDeclaree;
  final List<String> photosPaths;

  const CreerColisRequested({
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.villeDepartId,
    required this.destinataireNom,
    required this.destinataireTelephone,
    required this.villeArriveeId,
    required this.adresseLivraison,
    required this.poids,
    this.description,
    this.typeColis = 'standard',
    this.valeurDeclaree,
    this.photosPaths = const [],
  });

  @override
  List<Object?> get props => [expediteurNom, destinataireNom, poids];
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
  final int page;
  const LoadMoreColis({this.statut, required this.page});
  @override
  List<Object?> get props => [statut, page];
}

class ResetColisState extends ColisEvent {}
