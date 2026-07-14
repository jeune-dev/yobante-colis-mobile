import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/failure.dart';
import '../../../paiements/domain/entities/facture_colis.dart';

// ── Model ──────────────────────────────────────────────────────────────────
class FactureColisModel extends FactureColis {
  const FactureColisModel({
    required super.id, required super.reference, required super.colisId,
    required super.montantTransport, required super.remise, required super.montantTotal,
    required super.statut, required super.dateEmission, super.dateLimitePaiement,
  });

  factory FactureColisModel.fromJson(Map<String, dynamic> j) => FactureColisModel(
        id: j['id'] as String,
        reference: j['reference'] as String? ?? '',
        colisId: j['colisId'] as String? ?? '',
        montantTransport: (j['montantTransport'] as num?)?.toDouble() ?? 0,
        remise: (j['remise'] as num?)?.toDouble() ?? 0,
        montantTotal: (j['montantTotal'] as num?)?.toDouble() ?? 0,
        statut: j['statut'] as String? ?? '',
        dateEmission: j['dateEmission'] as String? ?? '',
        dateLimitePaiement: j['dateLimitePaiement'] as String?,
      );
}

// ── Events ─────────────────────────────────────────────────────────────────
abstract class PaiementsEvent extends Equatable {
  const PaiementsEvent();
  @override List<Object?> get props => [];
}
class LoadFactures extends PaiementsEvent { const LoadFactures(); }
class LoadFactureDetail extends PaiementsEvent {
  final String id;
  const LoadFactureDetail(this.id);
  @override List<Object?> get props => [id];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class PaiementsState extends Equatable {
  const PaiementsState();
  @override List<Object?> get props => [];
}
class PaiementsInitial extends PaiementsState {}
class PaiementsLoading extends PaiementsState {}
class FacturesLoaded extends PaiementsState {
  final List<FactureColis> factures;
  const FacturesLoaded(this.factures);
  @override List<Object?> get props => [factures];
}
class FactureDetailLoaded extends PaiementsState {
  final FactureColis facture;
  const FactureDetailLoaded(this.facture);
  @override List<Object?> get props => [facture];
}
class PaiementsFailure extends PaiementsState {
  final String message;
  const PaiementsFailure(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class PaiementsBloc extends Bloc<PaiementsEvent, PaiementsState> {
  final Dio dio;
  PaiementsBloc({required this.dio}) : super(PaiementsInitial()) {
    on<LoadFactures>(_onLoadFactures);
    on<LoadFactureDetail>(_onLoadDetail);
  }

  Future<void> _onLoadFactures(LoadFactures _, Emitter<PaiementsState> emit) async {
    emit(PaiementsLoading());
    try {
      final res = await dio.get(Env.clientFactures);
      final list = res.data['data']['factures'] as List;
      emit(FacturesLoaded(list.map((e) => FactureColisModel.fromJson(e as Map<String, dynamic>)).toList()));
    } catch (e) {
      emit(PaiementsFailure(e.toString()));
    }
  }

  Future<void> _onLoadDetail(LoadFactureDetail event, Emitter<PaiementsState> emit) async {
    emit(PaiementsLoading());
    try {
      final res = await dio.get(Env.clientFactureId(event.id));
      emit(FactureDetailLoaded(FactureColisModel.fromJson(res.data['data']['facture'] as Map<String, dynamic>)));
    } catch (e) {
      emit(PaiementsFailure(e.toString()));
    }
  }
}
