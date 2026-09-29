import 'package:equatable/equatable.dart';

/// Les décimaux PostgreSQL arrivent en chaîne (« 5.000 ») : conversion tolérante.
double? versDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

/// Référence légère vers une ville, telle que renvoyée imbriquée dans un colis.
class VilleRef extends Equatable {
  final String id;
  final String nom;
  final String? pays;
  const VilleRef({required this.id, required this.nom, this.pays});

  factory VilleRef.fromJson(Map<String, dynamic> json) => VilleRef(
        id: json['id'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        pays: json['pays'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

/// Référence légère vers un service d'expédition (Express, Standard...).
class ServiceRef extends Equatable {
  final String id;
  final String code;
  final String nom;
  const ServiceRef({required this.id, required this.code, required this.nom});

  factory ServiceRef.fromJson(Map<String, dynamic> json) => ServiceRef(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id];
}

/// Référence légère vers un point de collecte/retrait.
class PointRef extends Equatable {
  final String id;
  final String? code;
  final String nom;
  final String? adresse;
  final String? telephone;
  final Map<String, dynamic>? horaires;
  const PointRef({
    required this.id,
    this.code,
    required this.nom,
    this.adresse,
    this.telephone,
    this.horaires,
  });

  factory PointRef.fromJson(Map<String, dynamic> json) => PointRef(
        id: json['id'] as String? ?? '',
        code: json['code'] as String?,
        nom: json['nom'] as String? ?? '',
        adresse: json['adresse'] as String?,
        telephone: json['telephone'] as String?,
        horaires: json['horaires'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [id];
}

/// Une pièce physique d'une expédition (colis multi-pièces).
class ColisPiece extends Equatable {
  final String? id;
  final String? designation;
  final String typeEmballage;
  final double poidsKg;
  final double? longueurCm;
  final double? largeurCm;
  final double? hauteurCm;

  const ColisPiece({
    this.id,
    this.designation,
    this.typeEmballage = 'carton',
    required this.poidsKg,
    this.longueurCm,
    this.largeurCm,
    this.hauteurCm,
  });

  factory ColisPiece.fromJson(Map<String, dynamic> json) => ColisPiece(
        id: json['id'] as String?,
        designation: json['designation'] as String?,
        typeEmballage: json['typeEmballage'] as String? ?? 'carton',
        poidsKg: versDouble(json['poidsKg']) ?? 0,
        longueurCm: versDouble(json['longueurCm']),
        largeurCm: versDouble(json['largeurCm']),
        hauteurCm: versDouble(json['hauteurCm']),
      );

  Map<String, dynamic> toJson() => {
        if (designation != null && designation!.isNotEmpty) 'designation': designation,
        'typeEmballage': typeEmballage,
        'poidsKg': poidsKg,
        if (longueurCm != null) 'longueurCm': longueurCm,
        if (largeurCm != null) 'largeurCm': largeurCm,
        if (hauteurCm != null) 'hauteurCm': hauteurCm,
      };

  @override
  List<Object?> get props => [id, poidsKg, designation];
}

/// Article de la grille forfaitaire retenu pour une expédition (prix figé).
class LigneForfaitColis extends Equatable {
  final String libelle;
  final int quantite;
  final double prixUnitaire;
  final double montant;
  final String devise;

  const LigneForfaitColis({
    required this.libelle,
    this.quantite = 1,
    this.prixUnitaire = 0,
    this.montant = 0,
    this.devise = 'EUR',
  });

  factory LigneForfaitColis.fromJson(Map<String, dynamic> json) => LigneForfaitColis(
        libelle: json['libelle'] as String? ?? '',
        quantite: (json['quantite'] as num?)?.toInt() ?? 1,
        prixUnitaire: versDouble(json['prixUnitaire']) ?? 0,
        montant: versDouble(json['montant']) ?? 0,
        devise: json['devise'] as String? ?? 'EUR',
      );

  @override
  List<Object?> get props => [libelle, quantite, montant];
}

/// Une expédition Yobante Express (corridor France ⇄ Sénégal).
class Colis extends Equatable {
  final String id;
  final String reference;
  final String? serviceId;
  final ServiceRef? service;

  final String typeContenu;
  final String? description;
  final bool fragile;
  final bool marchandiseDangereuse;

  final String expediteurNom;
  final String? expediteurEntreprise;
  final String expediteurTelephone;
  final String? expediteurEmail;
  final String? paysDepart;
  final String villeDepartId;
  final VilleRef? villeDepart;
  final String? adresseDepart;
  final String? codePostalDepart;

  final String destinataireNom;
  final String? destinataireEntreprise;
  final String destinataireTelephone;
  final String? destinataireEmail;
  final String? paysArrivee;
  final String villeArriveeId;
  final VilleRef? villeArrivee;
  final String? adresseLivraison;
  final String? codePostalArrivee;
  final String? instructionsLivraison;

  final String modeDepot;
  final String? pointCollecteDepartId;
  final PointRef? pointCollecteDepart;
  final String modeLivraison;
  final String? pointRetraitId;
  final PointRef? pointRetrait;

  final int nbPieces;
  final double poidsReelKg;
  final double poidsFactureKg;
  final List<ColisPiece> pieces;

  final double valeurDeclaree;
  final String deviseValeur;
  final bool assuranceSouscrite;

  final String incoterm;
  final String payeur;

  final String devise;
  final double montantTotal;

  final String statut;
  final String? dateLivraisonEstimee;
  final String? dateLivraisonEffective;
  final String? dateLimiteRetrait;
  final String? codeRetrait;

  final List<String> photos;
  final String? annuleMotif;
  final String? motifIncident;
  final bool enRetard;
  final DateTime createdAt;

  // ── Cahier des charges : catégorie et parcours ─────────────────────────────
  /// `documents`, `colis_moyen` ou `colis_xxl`.
  final String categorie;
  final String? typeDocument;
  final String? etatMarchandise;
  final String? destinataireQuartier;
  final String? destinataireArrondissement;
  final String? destinataireDepartement;
  final String? destinatairePointRepere;
  final List<LigneForfaitColis> lignesForfait;
  final Map<String, dynamic> infosCollecte;
  final bool optionColissimo;

  /// Catégorie 3 : proposition tarifaire de l'administrateur.
  final double? montantPropose;
  final String? propositionCommentaire;
  final String? propositionExpireAt;
  final String? motifRefus;
  final String? dateLimiteEtude;

  /// Renseignés par le détail : modifiable avant l'arrivée au Sénégal, lien de
  /// paiement de la facture due, adresse de réception pour un dépôt ou un envoi postal.
  final bool modifiable;
  final String? lienPaiement;
  final String? factureReference;
  final String? factureStatut;
  final Map<String, dynamic>? adresseReception;
  final String? tourneeTitre;
  final String? dateCollecte;

  const Colis({
    required this.id,
    required this.reference,
    this.serviceId,
    this.service,
    this.typeContenu = 'marchandise',
    this.description,
    this.fragile = false,
    this.marchandiseDangereuse = false,
    required this.expediteurNom,
    this.expediteurEntreprise,
    required this.expediteurTelephone,
    this.expediteurEmail,
    this.paysDepart,
    required this.villeDepartId,
    this.villeDepart,
    this.adresseDepart,
    this.codePostalDepart,
    required this.destinataireNom,
    this.destinataireEntreprise,
    required this.destinataireTelephone,
    this.destinataireEmail,
    this.paysArrivee,
    required this.villeArriveeId,
    this.villeArrivee,
    this.adresseLivraison,
    this.codePostalArrivee,
    this.instructionsLivraison,
    this.modeDepot = 'point_collecte',
    this.pointCollecteDepartId,
    this.pointCollecteDepart,
    this.modeLivraison = 'point_retrait',
    this.pointRetraitId,
    this.pointRetrait,
    this.nbPieces = 1,
    this.poidsReelKg = 0,
    this.poidsFactureKg = 0,
    this.pieces = const [],
    this.valeurDeclaree = 0,
    this.deviseValeur = 'XOF',
    this.assuranceSouscrite = false,
    this.incoterm = 'DAP',
    this.payeur = 'expediteur',
    this.devise = 'XOF',
    this.montantTotal = 0,
    required this.statut,
    this.dateLivraisonEstimee,
    this.dateLivraisonEffective,
    this.dateLimiteRetrait,
    this.codeRetrait,
    required this.photos,
    this.annuleMotif,
    this.motifIncident,
    this.enRetard = false,
    required this.createdAt,
    this.categorie = 'colis_moyen',
    this.typeDocument,
    this.etatMarchandise,
    this.destinataireQuartier,
    this.destinataireArrondissement,
    this.destinataireDepartement,
    this.destinatairePointRepere,
    this.lignesForfait = const [],
    this.infosCollecte = const {},
    this.optionColissimo = false,
    this.montantPropose,
    this.propositionCommentaire,
    this.propositionExpireAt,
    this.motifRefus,
    this.dateLimiteEtude,
    this.modifiable = false,
    this.lienPaiement,
    this.factureReference,
    this.factureStatut,
    this.adresseReception,
    this.tourneeTitre,
    this.dateCollecte,
  });

  /// Montant non encore arrêté (colis XXL en cours d'étude).
  bool get montantEnAttente => montantTotal <= 0 && categorie == 'colis_xxl';

  /// Vrai si le trajet traverse une frontière (France ⇄ Sénégal).
  bool get estInternational =>
      paysDepart != null && paysArrivee != null && paysDepart != paysArrivee;

  @override
  List<Object?> get props => [id, reference, statut];
}

/// Un événement du fil de suivi d'une expédition.
class SuiviEvenement extends Equatable {
  final String? code;
  final String statut;
  final String libelle;
  final String? lieu;
  final String? pays;
  final String? commentaire;
  final DateTime date;

  const SuiviEvenement({
    this.code,
    required this.statut,
    required this.libelle,
    this.lieu,
    this.pays,
    this.commentaire,
    required this.date,
  });

  factory SuiviEvenement.fromJson(Map<String, dynamic> json) => SuiviEvenement(
        code: (json['code'] ?? json['codeEvenement']) as String?,
        statut: json['statut'] as String? ?? '',
        libelle: json['libelle'] as String? ?? '',
        lieu: json['lieu'] as String?,
        pays: json['pays'] as String?,
        commentaire: json['commentaire'] as String?,
        date: DateTime.tryParse((json['date'] ?? json['dateEvenement'] ?? '').toString()) ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [code, statut, date];
}
