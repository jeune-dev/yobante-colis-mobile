import 'package:equatable/equatable.dart';
import '../../domain/entities/ville.dart';

abstract class VillesState extends Equatable {
  const VillesState();
  @override
  List<Object?> get props => [];
}

class VillesInitial extends VillesState {}

class VillesLoading extends VillesState {}

class VillesLoaded extends VillesState {
  final List<Ville> villes;
  const VillesLoaded(this.villes);
  @override
  List<Object?> get props => [villes];
}

class VillesFailure extends VillesState {
  final String message;
  const VillesFailure(this.message);
  @override
  List<Object?> get props => [message];
}
