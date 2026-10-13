import 'package:equatable/equatable.dart';

class FactureColis extends Equatable {
  final String id;
  final String reference;
  final String colisId;
  final double montantTransport;
  final double remise;
  final double montantTotal;

  /// Détail du montant, tel que facturé par le backend (0 si absent).
  final double montantSurcharges;
  final double montantAssurance;
  final double montantHt;
  final double montantTva;
  final double montantDroitsDouane;
  final String statut;
  final String dateEmission;
  final String? dateLimitePaiement;

  /// Devise de facturation : EUR au départ de la France, XOF au départ du Sénégal.
  final String devise;
  final double montantPaye;

  /// Avoirs imputés sur la facture : ils réduisent le reste dû sans être des règlements.
  final double montantAvoirs;

  /// « avoir » : somme due au client (indemnisation, remboursement), jamais à payer.
  final String type;

  /// Lien de paiement en ligne, fourni par le backend tant que la facture est due.
  final String? lienPaiement;
  final String? colisReference;

  const FactureColis({
    required this.id,
    required this.reference,
    required this.colisId,
    required this.montantTransport,
    required this.remise,
    required this.montantTotal,
    required this.statut,
    required this.dateEmission,
    this.dateLimitePaiement,
    this.devise = 'XOF',
    this.montantPaye = 0,
    this.montantAvoirs = 0,
    this.type = 'expedition',
    this.lienPaiement,
    this.colisReference,
    this.montantSurcharges = 0,
    this.montantAssurance = 0,
    this.montantHt = 0,
    this.montantTva = 0,
    this.montantDroitsDouane = 0,
  });

  bool get estAvoir => type == 'avoir';

  double get soldeDu =>
      estAvoir ? 0 : (montantTotal - montantPaye - montantAvoirs).clamp(0, double.infinity).toDouble();

  @override
  List<Object?> get props => [id];
}
