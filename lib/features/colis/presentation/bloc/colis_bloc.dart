import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/colis_usecases.dart';
import 'colis_event.dart';
import 'colis_state.dart';
import '../../../../core/errors/failure.dart';

class ColisBloc extends Bloc<ColisEvent, ColisState> {
  final GetColis getColis;
  final GetColisRecus getColisRecus;
  final GetColisDetail getColisDetail;
  final CreerColis creerColis;
  final GetSuiviColis getSuiviColis;
  final AnnulerColis annulerColis;
  final RepondreProposition repondreProposition;
  final ModifierColis modifierColis;

  ColisBloc({
    required this.getColis,
    required this.getColisRecus,
    required this.getColisDetail,
    required this.creerColis,
    required this.getSuiviColis,
    required this.annulerColis,
    required this.repondreProposition,
    required this.modifierColis,
  }) : super(ColisInitial()) {
    on<LoadColis>(_onLoadColis);
    on<LoadMoreColis>(_onLoadMoreColis);
    on<LoadColisRecus>(_onLoadColisRecus);
    on<LoadMoreColisRecus>(_onLoadMoreColisRecus);
    on<LoadColisDetail>(_onLoadColisDetail);
    on<LoadSuiviColis>(_onLoadSuiviColis);
    on<CreerColisRequested>(_onCreerColis);
    on<AnnulerColisRequested>(_onAnnulerColis);
    on<AccepterPropositionRequested>(_onAccepterProposition);
    on<RefuserPropositionRequested>(_onRefuserProposition);
    on<ModifierColisRequested>(_onModifierColis);
    on<ResetColisState>((_, emit) => emit(ColisInitial()));
  }

  Future<void> _onLoadColis(LoadColis event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColis(statut: event.statut, filtres: event.filtres, page: 1);
    result.fold(
      (f) => emit(_echec(f)),
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
    final result = await getColis(statut: event.statut, filtres: event.filtres, page: event.page);
    result.fold(
      (f) => emit(_echec(f)),
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

  Future<void> _onLoadColisRecus(LoadColisRecus event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColisRecus(statut: event.statut, filtres: event.filtres, page: 1);
    result.fold(
      (f) => emit(_echec(f)),
      (data) {
        final pagination = data['pagination'] as Map<String, dynamic>?;
        emit(ColisRecusLoaded(
          colis: List.from(data['colis'] as List),
          pagination: pagination,
          currentPage: 1,
          hasMore: _hasNextPage(pagination),
        ));
      },
    );
  }

  Future<void> _onLoadMoreColisRecus(LoadMoreColisRecus event, Emitter<ColisState> emit) async {
    final current = state;
    if (current is! ColisRecusLoaded) return;
    final result = await getColisRecus(statut: event.statut, filtres: event.filtres, page: event.page);
    result.fold(
      (f) => emit(_echec(f)),
      (data) {
        final pagination = data['pagination'] as Map<String, dynamic>?;
        emit(ColisRecusLoaded(
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
    // Contrat : { totalItems, totalPages, currentPage, pageSize }
    final page = ((p['currentPage'] ?? p['page']) as num?)?.toInt();
    final total = (p['totalPages'] as num?)?.toInt();
    return page != null && total != null && page < total;
  }

  Future<void> _onLoadColisDetail(LoadColisDetail event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getColisDetail(event.id);
    result.fold((f) => emit(_echec(f)), (c) => emit(ColisDetailLoaded(c)));
  }

  Future<void> _onLoadSuiviColis(LoadSuiviColis event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await getSuiviColis(event.id);
    result.fold((f) => emit(_echec(f)), (h) => emit(SuiviColisLoaded(h)));
  }

  Future<void> _onCreerColis(CreerColisRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());

    final progressCtrl = StreamController<double>();

    // Lance l'upload ; ferme le stream de progression quand terminé (succès ou erreur)
    final uploadFuture = creerColis(
      event.demande,
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
      (f) => emit(_echec(f)),
      (resultat) => emit(ColisCreated(resultat)),
    );
  }

  Future<void> _onAnnulerColis(AnnulerColisRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await annulerColis(event.id, motif: event.motif);
    result.fold((f) => emit(_echec(f)), (r) => emit(ColisAnnule(r.valeur, message: r.message)));
  }

  Future<void> _onAccepterProposition(AccepterPropositionRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await repondreProposition.accepter(event.id);
    result.fold((f) => emit(_echec(f)), (r) => emit(PropositionAcceptee(r)));
  }

  Future<void> _onRefuserProposition(RefuserPropositionRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await repondreProposition.refuser(event.id, motif: event.motif);
    result.fold((f) => emit(_echec(f)), (r) => emit(PropositionRefusee(r.valeur, message: r.message)));
  }

  Future<void> _onModifierColis(ModifierColisRequested event, Emitter<ColisState> emit) async {
    emit(ColisLoading());
    final result = await modifierColis(event.id, event.champs);
    result.fold((f) => emit(_echec(f)), (r) => emit(ColisModifie(r.valeur, message: r.message)));
  }

  ColisFailure _echec(Failure f) => ColisFailure(f.errorMessage, code: f is ServerFailure ? f.code : null);
}
