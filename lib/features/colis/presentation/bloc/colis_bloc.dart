import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/colis_usecases.dart';
import 'colis_event.dart';
import 'colis_state.dart';

class ColisBloc extends Bloc<ColisEvent, ColisState> {
  final GetColis getColis;
  final GetColisDetail getColisDetail;
  final CreerColis creerColis;
  final GetSuiviColis getSuiviColis;
  final AnnulerColis annulerColis;

  ColisBloc({
    required this.getColis,
    required this.getColisDetail,
    required this.creerColis,
    required this.getSuiviColis,
    required this.annulerColis,
  }) : super(ColisInitial()) {
    on<LoadColis>(_onLoadColis);
    on<LoadColisDetail>(_onLoadColisDetail);
    on<LoadSuiviColis>(_onLoadSuiviColis);
    on<CreerColisRequested>(_onCreerColis);
    on<AnnulerColisRequested>(_onAnnulerColis);
    on<ResetColisState>((_, emit) => emit(ColisInitial()));
  }

  Future<void> _onLoadColis(LoadColis event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColis(statut: event.statut, page: event.page);
    result.fold(
      (f) => emit(ColisFailure(f.errorMessage)),
      (data) => emit(ColisListLoaded(
        colis: List.from(data['colis'] as List),
        pagination: data['pagination'] as Map<String, dynamic>?,
      )),
    );
  }

  Future<void> _onLoadColisDetail(LoadColisDetail event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColisDetail(event.id);
    result.fold((f) => emit(ColisFailure(f.errorMessage)), (c) => emit(ColisDetailLoaded(c)));
  }

  Future<void> _onLoadSuiviColis(LoadSuiviColis event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getSuiviColis(event.id);
    result.fold((f) => emit(ColisFailure(f.errorMessage)), (h) => emit(SuiviColisLoaded(h)));
  }

  Future<void> _onCreerColis(CreerColisRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await creerColis(
      expediteurNom: event.expediteurNom,
      expediteurTelephone: event.expediteurTelephone,
      villeDepartId: event.villeDepartId,
      destinataireNom: event.destinataireNom,
      destinataireTelephone: event.destinataireTelephone,
      villeArriveeId: event.villeArriveeId,
      adresseLivraison: event.adresseLivraison,
      poids: event.poids,
      description: event.description,
      typeColis: event.typeColis,
      valeurDeclaree: event.valeurDeclaree,
      photosPaths: event.photosPaths,
      onSendProgress: (sent, total) {
        if (total > 0) emit(ColisUploadProgress(sent / total));
      },
    );
    result.fold(
      (f) => emit(ColisFailure(f.errorMessage)),
      (data) => emit(ColisCreated(
        colis: data['colis'],
        facture: data['facture'] as Map<String, dynamic>?,
      )),
    );
  }

  Future<void> _onAnnulerColis(AnnulerColisRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await annulerColis(event.id, motif: event.motif);
    result.fold((f) => emit(ColisFailure(f.errorMessage)), (c) => emit(ColisAnnule(c)));
  }
}
