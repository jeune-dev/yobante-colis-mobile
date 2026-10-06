import 'package:equatable/equatable.dart';

abstract class PaiementsEvent extends Equatable {
  const PaiementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFactures extends PaiementsEvent {
  final String? statut;
  final bool impayees;
  const LoadFactures({this.statut, this.impayees = false});
  @override
  List<Object?> get props => [statut, impayees];
}

class LoadFactureDetail extends PaiementsEvent {
  final String id;
  const LoadFactureDetail(this.id);
  @override
  List<Object?> get props => [id];
}
