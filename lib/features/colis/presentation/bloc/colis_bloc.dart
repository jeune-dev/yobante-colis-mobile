import 'dart:async';
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
    on<LoadMoreColis>(_onLoadMoreColis);
    on<LoadColisDetail>(_onLoadColisDetail);
    on<LoadSuiviColis>(_onLoadSuiviColis);
    on<CreerColisRequested>(_onCreerColis);
    on<AnnulerColisRequested>(_onAnnulerColis);
    on<ResetColisState>((_, emit) => emit(ColisInitial()));
  }

  Future<void> _onLoadColis(LoadColis event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColis(statut: event.statut, page: 1);
    result.fold(
      (f) => emit(ColisFailure(f.errorMessage)),
      (data) {
        final pagination = data['pagination'] as Map<String, dynamic>?;
        emit(ColisListLoaded(
          colis: List.from(data['colis'] as List),
          pagination: pagination,
          currentPage: 1,
          hasMore: _hasNextPage(pagination),
        ));
      },
    );
  }

  Future<void> _onLoadMoreColis(LoadMoreColis event, Emitter<ColisState> emit) async {
    final current = state;
    if (current is! ColisListLoaded) return;
    final result = await getColis(statut: event.statut, page: event.page);
    result.fold(
      (f) => emit(ColisFailure(f.errorMessage)),
      (data) {
        final pagination = data['pagination'] as Map<String, dynamic>?;
        emit(ColisListLoaded(
          colis: [...current.colis, ...List<dynamic>.from(data['colis'] as List).cast()],
          pagination: pagination,
          currentPage: event.page,
          hasMore: _hasNextPage(pagination),
        ));
      },
    );
  }

  static bool _hasNextPage(Map<String, dynamic>? p) {
    if (p == null) return false;
    if (p['hasNextPage'] == true) return true;
    final page = p['page'] as int?;
    final total = p['totalPages'] as int?;
    return page != null && total != null && page < total;
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

    final progressCtrl = StreamController<double>();

    // Lance l'upload ; ferme le stream de progression quand terminé (succès ou erreur)
    final uploadFuture = creerColis(
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
        if (total > 0 && !progressCtrl.isClosed) progressCtrl.add(sent / total);
      },
    ).whenComplete(progressCtrl.close);

    // Consomme les événements de progression via emit.forEach (pattern BLoC recommandé)
    await emit.forEach<double>(
      progressCtrl.stream,
      onData: (p) => ColisUploadProgress(p),
    );

    final result = await uploadFuture;
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
