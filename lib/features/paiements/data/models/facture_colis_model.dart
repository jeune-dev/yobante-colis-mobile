import '../../domain/entities/facture_colis.dart';

class FactureColisModel extends FactureColis {
  const FactureColisModel({
    required super.id,
    required super.reference,
    required super.colisId,
    required super.montantTransport,
    required super.remise,
    required super.montantTotal,
    required super.statut,
    required super.dateEmission,
    super.dateLimitePaiement,
  });

  factory FactureColisModel.fromJson(Map<String, dynamic> j) => FactureColisModel(
    id: j['id'] as String? ?? '',
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
