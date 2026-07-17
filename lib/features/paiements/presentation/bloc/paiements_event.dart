import 'package:equatable/equatable.dart';

abstract class PaiementsEvent extends Equatable {
  const PaiementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFactures extends PaiementsEvent {
  const LoadFactures();
}

class LoadFactureDetail extends PaiementsEvent {
  final String id;
  const LoadFactureDetail(this.id);
  @override
  List<Object?> get props => [id];
}
