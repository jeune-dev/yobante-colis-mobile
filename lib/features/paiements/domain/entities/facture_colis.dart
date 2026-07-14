import 'package:equatable/equatable.dart';

class FactureColis extends Equatable {
  final String id;
  final String reference;
  final String colisId;
  final double montantTransport;
  final double remise;
  final double montantTotal;
  final String statut;
  final String dateEmission;
  final String? dateLimitePaiement;

  const FactureColis({
    required this.id, required this.reference, required this.colisId,
    required this.montantTransport, required this.remise, required this.montantTotal,
    required this.statut, required this.dateEmission, this.dateLimitePaiement,
  });

  @override
  List<Object?> get props => [id];
}
