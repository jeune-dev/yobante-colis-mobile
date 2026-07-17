import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/paiements_repository.dart';
import 'paiements_event.dart';
import 'paiements_state.dart';

class PaiementsBloc extends Bloc<PaiementsEvent, PaiementsState> {
  final PaiementsRepository paiementsRepository;

  PaiementsBloc({required this.paiementsRepository}) : super(PaiementsInitial()) {
    on<LoadFactures>(_onLoadFactures);
    on<LoadFactureDetail>(_onLoadDetail);
  }

  Future<void> _onLoadFactures(LoadFactures _, Emitter<PaiementsState> emit) async {
    emit(PaiementsLoading());
    final result = await paiementsRepository.getFactures();
    result.fold(
      (f) => emit(PaiementsFailure(f.errorMessage)),
      (factures) => emit(FacturesLoaded(factures)),
    );
  }

  Future<void> _onLoadDetail(LoadFactureDetail event, Emitter<PaiementsState> emit) async {
    emit(PaiementsLoading());
    final result = await paiementsRepository.getFactureDetail(event.id);
    result.fold(
      (f) => emit(PaiementsFailure(f.errorMessage)),
      (facture) => emit(FactureDetailLoaded(facture)),
    );
  }
}
