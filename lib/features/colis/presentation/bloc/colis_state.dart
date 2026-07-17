import 'package:equatable/equatable.dart';
import '../../domain/entities/colis.dart';

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

class ColisDetailLoaded extends ColisState {
  final Colis colis;
  const ColisDetailLoaded(this.colis);
  @override
  List<Object?> get props => [colis];
}

class SuiviColisLoaded extends ColisState {
  final List<SuiviColis> historique;
  const SuiviColisLoaded(this.historique);
  @override
  List<Object?> get props => [historique];
}

class ColisCreated extends ColisState {
  final Colis colis;
  final Map<String, dynamic>? facture;
  const ColisCreated({required this.colis, this.facture});
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
