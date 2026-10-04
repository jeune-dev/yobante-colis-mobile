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

  /// Lien de paiement en ligne, fourni par le backend tant que la facture est due.
  final String? lienPaiement;
  final String? colisReference;

  const FactureColis({
    required this.id, required this.reference, required this.colisId,
    required this.montantTransport, required this.remise, required this.montantTotal,
    required this.statut, required this.dateEmission, this.dateLimitePaiement,
    this.devise = 'XOF',
    this.montantPaye = 0,
    this.lienPaiement,
    this.colisReference,
    this.montantSurcharges = 0,
    this.montantAssurance = 0,
    this.montantHt = 0,
    this.montantTva = 0,
    this.montantDroitsDouane = 0,
  });

  double get soldeDu => (montantTotal - montantPaye).clamp(0, double.infinity).toDouble();

  @override
  List<Object?> get props => [id];
}
