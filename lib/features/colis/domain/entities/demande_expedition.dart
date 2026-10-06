import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'colis.dart';

/// Article de la grille forfaitaire choisi par le client.
class ArticleChoisi extends Equatable {
  final String articleTarifId;
  final String libelle;
  final int quantite;
  const ArticleChoisi({required this.articleTarifId, required this.libelle, this.quantite = 1});

  Map<String, dynamic> toJson() => {'articleTarifId': articleTarifId, 'quantite': quantite};

  @override
  List<Object?> get props => [articleTarifId, quantite];
}

/// Types d'emballage acceptés par le backend (`TYPES_EMBALLAGE`).
const Map<String, String> kTypesEmballage = {
  'carton': 'Carton',
  'enveloppe': 'Enveloppe',
  'sac': 'Sac',
  'valise': 'Valise',
  'barigot': 'Barigot',
  'malle': 'Malle',
  'fut': 'Fût',
  'palette': 'Palette',
  'autre': 'Autre',
};

/// Unités de quantité acceptées pour l'inventaire douanier.
const Map<String, String> kUnitesDouane = {
  'piece': 'Pièce',
  'kg': 'Kg',
  'litre': 'Litre',
  'metre': 'Mètre',
  'paire': 'Paire',
  'lot': 'Lot',
};

/// Colis décrit par ses dimensions et son poids (colis au poids, colis XXL).
class PieceDeclaree extends Equatable {
  final double poidsKg;
  final double? longueurCm;
  final double? largeurCm;
  final double? hauteurCm;
  final String? designation;
  final String typeEmballage;
  const PieceDeclaree({
    required this.poidsKg,
    this.longueurCm,
    this.largeurCm,
    this.hauteurCm,
    this.designation,
    this.typeEmballage = 'carton',
  });

  Map<String, dynamic> toJson() => {
        'poidsKg': poidsKg,
        if (longueurCm != null) 'longueurCm': longueurCm,
        if (largeurCm != null) 'largeurCm': largeurCm,
        if (hauteurCm != null) 'hauteurCm': hauteurCm,
        if (designation != null && designation!.isNotEmpty) 'designation': designation,
        'typeEmballage': typeEmballage,
      };

  @override
  List<Object?> get props => [poidsKg, longueurCm, largeurCm, hauteurCm, designation, typeEmballage];
}

/// Ligne de contenu déclarée (produit, quantité, valeur, état) — reprise en
/// douane et dans l'inventaire des chargements.
class ContenuDeclare extends Equatable {
  final String designation;
  final double quantite;
  final String unite;
  final double valeurUnitaire;
  final String? etat;

  /// Code du système harmonisé (6 à 10 chiffres), s'il est connu.
  final String? codeSh;
  final double? poidsNetKg;

  /// Pays d'origine, code ISO à deux lettres (FR, CN…).
  final String? paysOrigine;
  final String? marque;
  const ContenuDeclare({
    required this.designation,
    this.quantite = 1,
    this.unite = 'piece',
    this.valeurUnitaire = 0,
    this.etat,
    this.codeSh,
    this.poidsNetKg,
    this.paysOrigine,
    this.marque,
  });

  Map<String, dynamic> toJson() => {
        'designation': designation,
        'quantite': quantite,
        'unite': unite,
        'valeurUnitaire': valeurUnitaire,
        if (etat != null) 'etat': etat,
        if (codeSh != null && codeSh!.isNotEmpty) 'codeSh': codeSh,
        'poidsNetKg': ?poidsNetKg,
        if (paysOrigine != null && paysOrigine!.isNotEmpty) 'paysOrigine': paysOrigine!.toUpperCase(),
        if (marque != null && marque!.isNotEmpty) 'marque': marque,
      };

  @override
  List<Object?> get props =>
      [designation, quantite, unite, valeurUnitaire, etat, codeSh, poidsNetKg, paysOrigine, marque];
}

/// Demande d'expédition complète, telle que saisie dans le parcours « Expédier ».
///
/// Elle sert à la fois au calcul du devis ([versDevis]) et à la déclaration
/// ([versFormulaire], envoyé en multipart avec les photos).
class DemandeExpedition extends Equatable {
  final String categorie;
  final String villeDepartId;
  final String villeArriveeId;
  final String? serviceId;

  /// Simulation de devis à l'origine de la commande (renvoyée par le backend).
  final String? simulationId;

  // Contenu
  final String? typeDocument;
  final String? etatMarchandise;
  final String? description;
  final double valeurDeclaree;
  final String deviseValeur;
  final List<ArticleChoisi> articles;
  final List<PieceDeclaree> pieces;
  final double? poidsKg;
  final List<ContenuDeclare> contenu;
  final Map<String, int> emballages;

  /// Nature de l'envoi (marchandise, cadeau, échantillon…) : conditionne la douane
  /// et les services proposés. Forcé à « document » par le backend en catégorie 1.
  final String typeContenu;
  final bool fragile;

  /// Contenu soumis à la réglementation des marchandises dangereuses (surcharge éventuelle).
  final bool marchandiseDangereuse;
  final bool assuranceSouscrite;

  /// Emballage du colis quand il est déclaré par son seul poids (sans pièces).
  final String? typeEmballage;

  /// DAP : droits réglés par le destinataire ; DDP : avancés par Yobante Colis et facturés.
  final String incoterm;

  /// Qui règle l'expédition : la devise de facturation suit son pays.
  final String payeur;
  final String? referenceClient;

  // Remise du colis
  final String modeDepot;
  final String? pointCollecteDepartId;
  final String? adresseDepart;
  final String? codePostalDepart;
  final bool optionColissimo;
  final String? tourneeCollecteId;
  final Map<String, dynamic> infosCollecte;

  // Expéditeur
  final String expediteurNom;
  final String? expediteurEntreprise;
  final String expediteurTelephone;
  final String? expediteurEmail;
  final String? numeroEori;
  final String? numeroNinea;

  // Destinataire
  final String destinataireNom;
  final String? destinataireEntreprise;
  final String destinataireTelephone;
  final String? destinataireEmail;
  final String modeLivraison;
  final String? pointRetraitId;
  final String? adresseLivraison;
  final String? codePostalArrivee;
  final String? instructionsLivraison;
  final String? destinataireQuartier;
  final String? destinataireArrondissement;
  final String? destinataireDepartement;
  final String? destinatairePointRepere;

  final bool conditionsAcceptees;

  const DemandeExpedition({
    required this.categorie,
    required this.villeDepartId,
    required this.villeArriveeId,
    this.serviceId,
    this.simulationId,
    this.typeDocument,
    this.etatMarchandise,
    this.description,
    this.valeurDeclaree = 0,
    this.deviseValeur = 'EUR',
    this.articles = const [],
    this.pieces = const [],
    this.poidsKg,
    this.contenu = const [],
    this.emballages = const {},
    this.typeContenu = 'marchandise',
    this.fragile = false,
    this.marchandiseDangereuse = false,
    this.assuranceSouscrite = false,
    this.typeEmballage,
    this.incoterm = 'DAP',
    this.payeur = 'expediteur',
    this.referenceClient,
    this.modeDepot = 'point_collecte',
    this.pointCollecteDepartId,
    this.adresseDepart,
    this.codePostalDepart,
    this.optionColissimo = false,
    this.tourneeCollecteId,
    this.infosCollecte = const {},
    this.expediteurNom = '',
    this.expediteurEntreprise,
    this.expediteurTelephone = '',
    this.expediteurEmail,
    this.numeroEori,
    this.numeroNinea,
    this.destinataireNom = '',
    this.destinataireEntreprise,
    this.destinataireTelephone = '',
    this.destinataireEmail,
    this.modeLivraison = 'livraison_domicile',
    this.pointRetraitId,
    this.adresseLivraison,
    this.codePostalArrivee,
    this.instructionsLivraison,
    this.destinataireQuartier,
    this.destinataireArrondissement,
    this.destinataireDepartement,
    this.destinatairePointRepere,
    this.conditionsAcceptees = false,
  });

  List<Map<String, dynamic>> get _emballagesJson => emballages.entries
      .where((e) => e.value > 0)
      .map((e) => {'emballageId': e.key, 'quantite': e.value})
      .toList();

  /// Champs du calcul de tarif (POST /public/devis ou /client/colis/devis).
  Map<String, dynamic> versDevis() => {
        'villeDepartId': villeDepartId,
        'villeArriveeId': villeArriveeId,
        'categorie': categorie,
        if (articles.isNotEmpty) 'articles': articles.map((a) => a.toJson()).toList(),
        if (_emballagesJson.isNotEmpty) 'emballages': _emballagesJson,
        if (pieces.isNotEmpty) 'pieces': pieces.map((p) => p.toJson()).toList(),
        if (pieces.isEmpty && poidsKg != null) 'poidsKg': poidsKg,
        'optionColissimo': optionColissimo,
        'modeDepot': modeDepot,
        'modeLivraison': modeLivraison,
        if (valeurDeclaree > 0) 'valeurDeclaree': valeurDeclaree,
        'deviseValeur': deviseValeur,
        'typeContenu': typeContenu,
        'fragile': fragile,
        'marchandiseDangereuse': marchandiseDangereuse,
        'assuranceSouscrite': assuranceSouscrite,
        'incoterm': incoterm,
        'payeur': payeur,
      };

  /// Champs du formulaire multipart de déclaration (POST /client/colis).
  /// Les tableaux et objets sont encodés en JSON, décodés côté backend.
  Map<String, dynamic> versFormulaire() {
    String? texte(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final champs = <String, dynamic>{
      'serviceId': serviceId,
      'simulationId': simulationId,
      'categorie': categorie,
      'typeDocument': texte(typeDocument),
      'etatMarchandise': etatMarchandise,
      'description': texte(description),
      'villeDepartId': villeDepartId,
      'villeArriveeId': villeArriveeId,
      'modeDepot': modeDepot,
      'pointCollecteDepartId': modeDepot == 'point_collecte' ? pointCollecteDepartId : null,
      'adresseDepart': modeDepot == 'point_collecte' || modeDepot == 'envoi_postal' ? null : texte(adresseDepart),
      'codePostalDepart': texte(codePostalDepart),
      'optionColissimo': modeDepot == 'envoi_postal' && optionColissimo ? 'true' : 'false',
      'tourneeCollecteId': modeDepot == 'enlevement_domicile' ? tourneeCollecteId : null,
      'expediteurNom': expediteurNom.trim(),
      'expediteurTelephone': expediteurTelephone,
      'expediteurEmail': texte(expediteurEmail),
      'destinataireNom': destinataireNom.trim(),
      'destinataireTelephone': destinataireTelephone,
      'destinataireEmail': texte(destinataireEmail),
      'modeLivraison': modeLivraison,
      'pointRetraitId': modeLivraison == 'point_retrait' ? pointRetraitId : null,
      'adresseLivraison': texte(adresseLivraison),
      'instructionsLivraison': texte(instructionsLivraison),
      'destinataireQuartier': texte(destinataireQuartier),
      'destinataireArrondissement': texte(destinataireArrondissement),
      'destinataireDepartement': texte(destinataireDepartement),
      'destinatairePointRepere': texte(destinatairePointRepere),
      'deviseValeur': deviseValeur,
      'typeContenu': typeContenu,
      'fragile': fragile ? 'true' : 'false',
      'marchandiseDangereuse': marchandiseDangereuse ? 'true' : 'false',
      'assuranceSouscrite': assuranceSouscrite ? 'true' : 'false',
      'incoterm': incoterm,
      'payeur': payeur,
      'referenceClient': texte(referenceClient),
      'expediteurEntreprise': texte(expediteurEntreprise),
      'destinataireEntreprise': texte(destinataireEntreprise),
      'numeroEori': texte(numeroEori),
      'numeroNinea': texte(numeroNinea),
      'codePostalArrivee': modeLivraison == 'livraison_domicile' ? texte(codePostalArrivee) : null,
      'conditionsAcceptees': conditionsAcceptees ? 'true' : 'false',
    };
    // Obligatoire pour la catégorie 2 (colis moyen), même à 0
    if (categorie == 'colis_moyen' || (categorie != 'documents' && valeurDeclaree > 0)) {
      champs['valeurDeclaree'] = '$valeurDeclaree';
    }
    if (articles.isNotEmpty) champs['articles'] = jsonEncode(articles.map((a) => a.toJson()).toList());
    if (pieces.isNotEmpty) {
      champs['pieces'] = jsonEncode(pieces.map((p) => p.toJson()).toList());
    } else if (poidsKg != null) {
      champs['poidsKg'] = '$poidsKg';
      if (typeEmballage != null) champs['typeEmballage'] = typeEmballage;
    }
    if (contenu.isNotEmpty) {
      champs['articlesDouane'] = jsonEncode(contenu.map((c) => c.toJson()).toList());
    }
    if (_emballagesJson.isNotEmpty) champs['emballages'] = jsonEncode(_emballagesJson);
    if (modeDepot == 'enlevement_domicile' && infosCollecte.isNotEmpty) {
      champs['infosCollecte'] = jsonEncode(infosCollecte);
    }
    champs.removeWhere((_, v) => v == null);
    return champs;
  }

  DemandeExpedition copyWith({
    String? serviceId,
    String? simulationId,
    bool? conditionsAcceptees,
  }) =>
      DemandeExpedition(
        categorie: categorie,
        villeDepartId: villeDepartId,
        villeArriveeId: villeArriveeId,
        serviceId: serviceId ?? this.serviceId,
        simulationId: simulationId ?? this.simulationId,
        typeDocument: typeDocument,
        etatMarchandise: etatMarchandise,
        description: description,
        valeurDeclaree: valeurDeclaree,
        deviseValeur: deviseValeur,
        articles: articles,
        pieces: pieces,
        poidsKg: poidsKg,
        contenu: contenu,
        emballages: emballages,
        typeContenu: typeContenu,
        fragile: fragile,
        marchandiseDangereuse: marchandiseDangereuse,
        assuranceSouscrite: assuranceSouscrite,
        typeEmballage: typeEmballage,
        incoterm: incoterm,
        payeur: payeur,
        referenceClient: referenceClient,
        modeDepot: modeDepot,
        pointCollecteDepartId: pointCollecteDepartId,
        adresseDepart: adresseDepart,
        codePostalDepart: codePostalDepart,
        optionColissimo: optionColissimo,
        tourneeCollecteId: tourneeCollecteId,
        infosCollecte: infosCollecte,
        expediteurNom: expediteurNom,
        expediteurEntreprise: expediteurEntreprise,
        expediteurTelephone: expediteurTelephone,
        expediteurEmail: expediteurEmail,
        numeroEori: numeroEori,
        numeroNinea: numeroNinea,
        destinataireNom: destinataireNom,
        destinataireEntreprise: destinataireEntreprise,
        destinataireTelephone: destinataireTelephone,
        destinataireEmail: destinataireEmail,
        modeLivraison: modeLivraison,
        pointRetraitId: pointRetraitId,
        adresseLivraison: adresseLivraison,
        codePostalArrivee: codePostalArrivee,
        instructionsLivraison: instructionsLivraison,
        destinataireQuartier: destinataireQuartier,
        destinataireArrondissement: destinataireArrondissement,
        destinataireDepartement: destinataireDepartement,
        destinatairePointRepere: destinatairePointRepere,
        conditionsAcceptees: conditionsAcceptees ?? this.conditionsAcceptees,
      );

  @override
  List<Object?> get props =>
      [
        categorie,
        villeDepartId,
        villeArriveeId,
        serviceId,
        articles,
        pieces,
        poidsKg,
        contenu,
        typeContenu,
        fragile,
        marchandiseDangereuse,
        incoterm,
        payeur,
      ];
}

/// Résultat d'une déclaration : l'expédition créée et ce que le client doit
/// faire ensuite (payer, déposer, attendre l'étude…).
class ResultatDeclaration {
  final Colis colis;
  final String message;
  final String? factureReference;
  final String? lienPaiement;
  final Map<String, dynamic>? adresseReception;
  const ResultatDeclaration({
    required this.colis,
    required this.message,
    this.factureReference,
    this.lienPaiement,
    this.adresseReception,
  });
}
