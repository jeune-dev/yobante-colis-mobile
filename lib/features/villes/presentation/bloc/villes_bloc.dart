import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_villes.dart';
import 'villes_event.dart';
import 'villes_state.dart';

export 'villes_event.dart';
export 'villes_state.dart';

class VillesBloc extends Bloc<VillesEvent, VillesState> {
  final GetVilles getVilles;

  VillesBloc({required this.getVilles}) : super(VillesInitial()) {
    on<LoadVilles>((_, emit) async {
      emit(VillesLoading());
      final result = await getVilles();
      result.fold(
        (f) => emit(VillesFailure(f.errorMessage)),
        (v) => emit(VillesLoaded(v)),
      );
    });
  }
}
