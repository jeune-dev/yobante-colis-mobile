import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ville.dart';
import '../../domain/usecases/get_villes.dart';

// Events
abstract class VillesEvent extends Equatable {
  const VillesEvent();
  @override List<Object?> get props => [];
}
class LoadVilles extends VillesEvent { const LoadVilles(); }

// States
abstract class VillesState extends Equatable {
  const VillesState();
  @override List<Object?> get props => [];
}
class VillesInitial extends VillesState {}
class VillesLoading extends VillesState {}
class VillesLoaded extends VillesState {
  final List<Ville> villes;
  const VillesLoaded(this.villes);
  @override List<Object?> get props => [villes];
}
class VillesFailure extends VillesState {
  final String message;
  const VillesFailure(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class VillesBloc extends Bloc<VillesEvent, VillesState> {
  final GetVilles getVilles;
  VillesBloc({required this.getVilles}) : super(VillesInitial()) {
    on<LoadVilles>((_, emit) async {
      emit(VillesLoading());
      final result = await getVilles();
      result.fold((f) => emit(VillesFailure(f.errorMessage)), (v) => emit(VillesLoaded(v)));
    });
  }
}
