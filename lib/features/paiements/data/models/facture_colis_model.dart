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
    super.devise,
    super.montantPaye,
    super.lienPaiement,
    super.colisReference,
    super.montantSurcharges,
    super.montantAssurance,
    super.montantHt,
    super.montantTva,
    super.montantDroitsDouane,
  });

  /// Les montants DECIMAL arrivent en chaîne depuis PostgreSQL (« 54.32 »).
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  factory FactureColisModel.fromJson(Map<String, dynamic> j) => FactureColisModel(
    id: j['id'] as String? ?? '',
    reference: j['reference'] as String? ?? '',
    colisId: j['colisId'] as String? ?? '',
    // Le backend nomme le fret « montantFret » ; « montantTransport » reste accepté (mode démo)
    montantTransport: _d(j['montantFret'] ?? j['montantTransport']),
    remise: _d(j['remise']),
    montantSurcharges: _d(j['montantSurcharges']),
    montantAssurance: _d(j['montantAssurance']),
    montantHt: _d(j['montantHt']),
    montantTva: _d(j['montantTva']),
    montantDroitsDouane: _d(j['montantDroitsDouane']),
    montantTotal: _d(j['montantTotal']),
    statut: j['statut'] as String? ?? '',
    dateEmission: j['dateEmission'] as String? ?? '',
    dateLimitePaiement: j['dateLimitePaiement'] as String?,
    devise: j['devise'] as String? ?? 'XOF',
    montantPaye: _d(j['montantPaye']),
    lienPaiement: j['lienPaiement'] as String?,
    colisReference: (j['colis'] as Map<String, dynamic>?)?['reference'] as String?,
  );
}
