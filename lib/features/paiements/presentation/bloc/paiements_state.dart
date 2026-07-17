import 'package:equatable/equatable.dart';
import '../../domain/entities/facture_colis.dart';

abstract class PaiementsState extends Equatable {
  const PaiementsState();
  @override
  List<Object?> get props => [];
}

class PaiementsInitial extends PaiementsState {}

class PaiementsLoading extends PaiementsState {}

class FacturesLoaded extends PaiementsState {
  final List<FactureColis> factures;
  const FacturesLoaded(this.factures);
  @override
  List<Object?> get props => [factures];
}

class FactureDetailLoaded extends PaiementsState {
  final FactureColis facture;
  const FactureDetailLoaded(this.facture);
  @override
  List<Object?> get props => [facture];
}

class PaiementsFailure extends PaiementsState {
  final String message;
  const PaiementsFailure(this.message);
  @override
  List<Object?> get props => [message];
}
