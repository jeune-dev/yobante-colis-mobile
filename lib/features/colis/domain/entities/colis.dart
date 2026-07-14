import 'package:equatable/equatable.dart';

class Colis extends Equatable {
  final String id;
  final String reference;
  final String expediteurNom;
  final String expediteurTelephone;
  final String villeDepartId;
  final String? villeDepartNom;
  final String destinataireNom;
  final String destinataireTelephone;
  final String villeArriveeId;
  final String? villeArriveeNom;
  final String adresseLivraison;
  final String? description;
  final String typeColis;
  final double poids;
  final double? valeurDeclaree;
  final double? montant;
  final String statut;
  final List<String> photos;
  final String? dateLivraisonEstimee;
  final String? dateLivraisonEffective;
  final String? annuleMotif;
  final DateTime createdAt;

  const Colis({
    required this.id,
    required this.reference,
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.villeDepartId,
    this.villeDepartNom,
    required this.destinataireNom,
    required this.destinataireTelephone,
    required this.villeArriveeId,
    this.villeArriveeNom,
    required this.adresseLivraison,
    this.description,
    required this.typeColis,
    required this.poids,
    this.valeurDeclaree,
    this.montant,
    required this.statut,
    required this.photos,
    this.dateLivraisonEstimee,
    this.dateLivraisonEffective,
    this.annuleMotif,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, reference, statut];
}

class SuiviColis extends Equatable {
  final String id;
  final String colisId;
  final String statut;
  final String? localisation;
  final String? commentaire;
  final DateTime createdAt;

  const SuiviColis({
    required this.id,
    required this.colisId,
    required this.statut,
    this.localisation,
    this.commentaire,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
