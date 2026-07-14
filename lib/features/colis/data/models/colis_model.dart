import '../../domain/entities/colis.dart';

class ColisModel extends Colis {
  const ColisModel({
    required super.id,
    required super.reference,
    required super.expediteurNom,
    required super.expediteurTelephone,
    required super.villeDepartId,
    super.villeDepartNom,
    required super.destinataireNom,
    required super.destinataireTelephone,
    required super.villeArriveeId,
    super.villeArriveeNom,
    required super.adresseLivraison,
    super.description,
    required super.typeColis,
    required super.poids,
    super.valeurDeclaree,
    super.montant,
    required super.statut,
    required super.photos,
    super.dateLivraisonEstimee,
    super.dateLivraisonEffective,
    super.annuleMotif,
    required super.createdAt,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) {
    final depart = json['villeDepart'] as Map<String, dynamic>?;
    final arrivee = json['villeArrivee'] as Map<String, dynamic>?;
    final rawPhotos = json['photos'];
    List<String> photos = [];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => e.toString()).toList();
    }
    return ColisModel(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      expediteurNom: json['expediteurNom'] as String? ?? '',
      expediteurTelephone: json['expediteurTelephone'] as String? ?? '',
      villeDepartId: json['villeDepartId'] as String? ?? depart?['id'] as String? ?? '',
      villeDepartNom: depart?['nom'] as String?,
      destinataireNom: json['destinataireNom'] as String? ?? '',
      destinataireTelephone: json['destinataireTelephone'] as String? ?? '',
      villeArriveeId: json['villeArriveeId'] as String? ?? arrivee?['id'] as String? ?? '',
      villeArriveeNom: arrivee?['nom'] as String?,
      adresseLivraison: json['adresseLivraison'] as String? ?? '',
      description: json['description'] as String?,
      typeColis: json['typeColis'] as String? ?? 'standard',
      poids: (json['poids'] as num?)?.toDouble() ?? 0,
      valeurDeclaree: (json['valeurDeclaree'] as num?)?.toDouble(),
      montant: (json['montant'] as num?)?.toDouble(),
      statut: json['statut'] as String? ?? 'en_attente',
      photos: photos,
      dateLivraisonEstimee: json['dateLivraisonEstimee'] as String?,
      dateLivraisonEffective: json['dateLivraisonEffective'] as String?,
      annuleMotif: json['annuleMotif'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SuiviColisModel extends SuiviColis {
  const SuiviColisModel({
    required super.id,
    required super.colisId,
    required super.statut,
    super.localisation,
    super.commentaire,
    required super.createdAt,
  });

  factory SuiviColisModel.fromJson(Map<String, dynamic> json) => SuiviColisModel(
        id: json['id'] as String,
        colisId: json['colisId'] as String? ?? '',
        statut: json['statut'] as String? ?? '',
        localisation: json['localisation'] as String?,
        commentaire: json['commentaire'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
