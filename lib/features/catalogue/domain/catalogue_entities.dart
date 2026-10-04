import 'package:equatable/equatable.dart';
import '../../../core/i18n/langue.dart';

/// Données publiques exposées par le backend pour le site vitrine et
/// l'application : services, grille forfaitaire, emballages, tournées de
/// collecte, annonces, configuration et résultats de devis.

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
double? _dn(dynamic v) => v == null ? null : _d(v);

class ServiceExpedition extends Equatable {
  final String id;
  final String code;
  final String nom;
  final String? description;
  final String modeTransport;
  final int? delaiMinJours;
  final int? delaiMaxJours;

  const ServiceExpedition({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    this.modeTransport = 'maritime',
    this.delaiMinJours,
    this.delaiMaxJours,
  });

  bool get estAerien => modeTransport == 'aerien';

  factory ServiceExpedition.fromJson(Map<String, dynamic> j) => ServiceExpedition(
        id: j['id'] as String,
        code: j['code'] as String? ?? '',
        nom: j['nom'] as String? ?? '',
        description: j['description'] as String?,
        modeTransport: j['modeTransport'] as String? ?? 'maritime',
        delaiMinJours: j['delaiMinJours'] as int?,
        delaiMaxJours: j['delaiMaxJours'] as int?,
      );

  @override
  List<Object?> get props => [id];
}

/// Article de la grille « Nature du colis » (prix Dakar / autres régions).
class ArticleTarif extends Equatable {
  final String id;
  final String code;
  final String libelle;
  final String? description;
  final String categorie;
  final String modeTransport;
  final double prixDakar;
  final double prixAutresRegions;
  final String devise;
  final bool prixAPartirDe;
  final double? poidsMaxKg;
  final String? photoUrl;

  const ArticleTarif({
    required this.id,
    required this.code,
    required this.libelle,
    this.description,
    required this.categorie,
    required this.modeTransport,
    required this.prixDakar,
    required this.prixAutresRegions,
    this.devise = 'EUR',
    this.prixAPartirDe = false,
    this.poidsMaxKg,
    this.photoUrl,
  });

  factory ArticleTarif.fromJson(Map<String, dynamic> j) => ArticleTarif(
        id: j['id'] as String,
        code: j['code'] as String? ?? '',
        libelle: j['libelle'] as String? ?? '',
        description: j['description'] as String?,
        categorie: j['categorie'] as String? ?? 'colis_moyen',
        modeTransport: j['modeTransport'] as String? ?? 'maritime',
        prixDakar: _d(j['prixDakar']),
        prixAutresRegions: _d(j['prixAutresRegions']),
        devise: j['devise'] as String? ?? 'EUR',
        prixAPartirDe: j['prixAPartirDe'] as bool? ?? false,
        poidsMaxKg: _dn(j['poidsMaxKg']),
        photoUrl: j['photoUrl'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

/// Barigot, carton à acheter ou prestation d'emballage.
class Emballage extends Equatable {
  final String id;
  final String code;
  final String libelle;
  final String? description;
  final String type;
  final double? longueurCm;
  final double? largeurCm;
  final double? hauteurCm;
  final double? capaciteKg;
  final double prix;
  final String devise;
  final List<String> photos;
  final bool disponible;

  const Emballage({
    required this.id,
    required this.code,
    required this.libelle,
    this.description,
    this.type = 'contenant',
    this.longueurCm,
    this.largeurCm,
    this.hauteurCm,
    this.capaciteKg,
    required this.prix,
    this.devise = 'EUR',
    this.photos = const [],
    this.disponible = true,
  });

  String? get dimensions => longueurCm != null && largeurCm != null && hauteurCm != null
      ? tr('${longueurCm!.toStringAsFixed(0)} × ${largeurCm!.toStringAsFixed(0)} × ${hauteurCm!.toStringAsFixed(0)} cm')
      : null;

  factory Emballage.fromJson(Map<String, dynamic> j) => Emballage(
        id: j['id'] as String,
        code: j['code'] as String? ?? '',
        libelle: j['libelle'] as String? ?? '',
        description: j['description'] as String?,
        type: j['type'] as String? ?? 'contenant',
        longueurCm: _dn(j['longueurCm']),
        largeurCm: _dn(j['largeurCm']),
        hauteurCm: _dn(j['hauteurCm']),
        capaciteKg: _dn(j['capaciteKg']),
        prix: _d(j['prix']),
        devise: j['devise'] as String? ?? 'EUR',
        photos: (j['photos'] as List? ?? [])
            .map((p) => p is Map ? '${p['url']}' : '$p')
            .toList(),
        disponible: j['disponible'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id];
}

/// Tournée de collecte à domicile programmée par l'administrateur.
class TourneeCollecte extends Equatable {
  final String id;
  final String reference;
  final String titre;
  final String pays;
  final String dateCollecte;
  final String? heureDebut;
  final String? heureFin;
  final String? dateLimiteInscription;
  final String? messageBanniere;
  final List<String> codesPostaux;
  final int? placesRestantes;

  const TourneeCollecte({
    required this.id,
    required this.reference,
    required this.titre,
    required this.pays,
    required this.dateCollecte,
    this.heureDebut,
    this.heureFin,
    this.dateLimiteInscription,
    this.messageBanniere,
    this.codesPostaux = const [],
    this.placesRestantes,
  });

  String? get horaires =>
      heureDebut != null && heureFin != null ? tr('de $heureDebut à $heureFin') : null;

  factory TourneeCollecte.fromJson(Map<String, dynamic> j) => TourneeCollecte(
        id: j['id'] as String,
        reference: j['reference'] as String? ?? '',
        titre: j['titre'] as String? ?? '',
        pays: j['pays'] as String? ?? 'FR',
        dateCollecte: j['dateCollecte'] as String? ?? '',
        heureDebut: j['heureDebut'] as String?,
        heureFin: j['heureFin'] as String?,
        dateLimiteInscription: j['dateLimiteInscription'] as String?,
        messageBanniere: j['messageBanniere'] as String?,
        codesPostaux: (j['codesPostaux'] as List? ?? []).map((e) => '$e').toList(),
        placesRestantes: j['placesRestantes'] as int?,
      );

  @override
  List<Object?> get props => [id];
}

/// Message publié par l'administrateur sur l'accueil de l'application.
class Annonce extends Equatable {
  final String id;
  final String titre;
  final String message;
  final String niveau;
  final String? lienUrl;
  final String? lienLibelle;
  final String? imageUrl;

  const Annonce({
    required this.id,
    required this.titre,
    required this.message,
    this.niveau = 'info',
    this.lienUrl,
    this.lienLibelle,
    this.imageUrl,
  });

  factory Annonce.fromJson(Map<String, dynamic> j) => Annonce(
        id: j['id'] as String,
        titre: j['titre'] as String? ?? '',
        message: j['message'] as String? ?? '',
        niveau: j['niveau'] as String? ?? 'info',
        lienUrl: j['lienUrl'] as String?,
        lienLibelle: j['lienLibelle'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

class ContenuAccueil {
  final List<Annonce> annonces;
  final List<TourneeCollecte> tournees;
  const ContenuAccueil({this.annonces = const [], this.tournees = const []});
}

/// Adresse de réception des colis (dépôt ou envoi postal), fixée par l'administrateur.
class AdresseReception {
  final String? nom;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? telephone;
  final String? instructions;
  const AdresseReception({
    this.nom,
    this.adresse,
    this.codePostal,
    this.ville,
    this.telephone,
    this.instructions,
  });

  String get lignes => [nom, adresse, [codePostal, ville].whereType<String>().where((s) => s.isNotEmpty).join(' ')]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join('\n');

  bool get estRenseignee => (adresse ?? '').trim().isNotEmpty;

  factory AdresseReception.fromJson(Map<String, dynamic>? j) => AdresseReception(
        nom: j?['nom'] as String?,
        adresse: j?['adresse'] as String?,
        codePostal: j?['codePostal'] as String?,
        ville: (j?['ville'] ?? j?['departement']) as String?,
        telephone: j?['telephone'] as String?,
        instructions: j?['instructions'] as String?,
      );
}

class PalierColissimo {
  final double poidsMaxKg;
  final double prixHt;
  const PalierColissimo(this.poidsMaxKg, this.prixHt);
}

/// Configuration publique : adresses de réception, liens, contact, options.
class ConfigurationPublique {
  final Map<String, AdresseReception> adresseReception;
  final Map<String, String> liens;
  final String? whatsappContact;
  final List<String> produitsInterdits;
  final bool collecteActive;
  final bool colissimoActive;
  final List<PalierColissimo> grilleColissimo;
  final bool prixForfaitsTtc;
  final int delaiEtudeHeures;
  final bool parrainageActif;
  final double remiseFilleulPourcent;
  final double gainParrainEur;
  final double remiseProPourcent;

  const ConfigurationPublique({
    this.adresseReception = const {},
    this.liens = const {},
    this.whatsappContact,
    this.produitsInterdits = const [],
    this.collecteActive = true,
    this.colissimoActive = true,
    this.grilleColissimo = const [],
    this.prixForfaitsTtc = true,
    this.delaiEtudeHeures = 24,
    this.parrainageActif = false,
    this.remiseFilleulPourcent = 0,
    this.gainParrainEur = 0,
    this.remiseProPourcent = 0,
  });

  String? lien(String cle) {
    final v = liens[cle];
    return v == null || v.isEmpty ? null : v;
  }

  factory ConfigurationPublique.fromJson(Map<String, dynamic> j) {
    final adresses = j['adresseReception'] as Map<String, dynamic>? ?? {};
    final collecte = j['collecte'] as Map<String, dynamic>? ?? {};
    final colissimo = j['colissimo'] as Map<String, dynamic>? ?? {};
    final parrainage = j['parrainage'] as Map<String, dynamic>? ?? {};
    return ConfigurationPublique(
      adresseReception: adresses.map((k, v) => MapEntry(k, AdresseReception.fromJson(v as Map<String, dynamic>?))),
      liens: (j['liens'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, '${v ?? ''}')),
      whatsappContact: (j['whatsappContact'] as String?)?.trim().isEmpty == true ? null : j['whatsappContact'] as String?,
      produitsInterdits: (j['produitsInterdits'] as List? ?? []).map((e) => '$e').toList(),
      collecteActive: collecte['active'] as bool? ?? true,
      colissimoActive: colissimo['active'] as bool? ?? true,
      grilleColissimo: (colissimo['grille'] as List? ?? [])
          .map((p) => PalierColissimo(_d(p['poidsMaxKg']), _d(p['prixHt'])))
          .toList(),
      prixForfaitsTtc: j['prixForfaitsTtc'] as bool? ?? true,
      delaiEtudeHeures: (j['delaiEtudeHeures'] as num?)?.toInt() ?? 24,
      parrainageActif: parrainage['actif'] as bool? ?? false,
      remiseFilleulPourcent: _d(parrainage['remiseFilleulPourcent']),
      gainParrainEur: _d(parrainage['gainParrainEur']),
      remiseProPourcent: _d(j['remiseProfessionnellePourcent']),
    );
  }
}

// ── Devis ────────────────────────────────────────────────────────────────────

class LigneDevis {
  final String libelle;
  final double montant;
  final int quantite;
  final String? devise;
  final bool prixAPartirDe;
  const LigneDevis({
    required this.libelle,
    required this.montant,
    this.quantite = 1,
    this.devise,
    this.prixAPartirDe = false,
  });
}

/// Une offre de service pour un besoin d'expédition (maritime, aérien…).
class OffreDevis extends Equatable {
  final ServiceExpedition service;
  final String devise;
  final double total;
  final double totalHt;
  final double tva;
  final double remise;
  final double creditParrainage;
  final double surcharges;
  final double assurance;

  /// Droits et taxes avancés (DDP uniquement) ; 0 en DAP.
  final double droitsDouane;
  final bool surDevis;
  final String modeTarification;
  final String? message;
  final String? dateLivraisonEstimee;
  final int? delaiJours;
  final double poidsFactureKg;
  final List<LigneDevis> lignesForfait;
  final List<LigneDevis> annexes;
  final String? zoneTarifaire;

  const OffreDevis({
    required this.service,
    required this.devise,
    required this.total,
    this.totalHt = 0,
    this.tva = 0,
    this.remise = 0,
    this.creditParrainage = 0,
    this.surcharges = 0,
    this.assurance = 0,
    this.droitsDouane = 0,
    this.surDevis = false,
    this.modeTarification = 'poids',
    this.message,
    this.dateLivraisonEstimee,
    this.delaiJours,
    this.poidsFactureKg = 0,
    this.lignesForfait = const [],
    this.annexes = const [],
    this.zoneTarifaire,
  });

  factory OffreDevis.fromJson(Map<String, dynamic> j) {
    final m = j['montants'] as Map<String, dynamic>? ?? {};
    final delai = j['delai'] as Map<String, dynamic>? ?? {};
    final corridor = j['corridor'] as Map<String, dynamic>? ?? {};
    return OffreDevis(
      service: ServiceExpedition.fromJson(j['service'] as Map<String, dynamic>),
      devise: j['devise'] as String? ?? 'EUR',
      total: _d(m['total']),
      totalHt: _d(m['totalHt']),
      tva: _d(m['tva']),
      remise: _d(m['remiseContractuelle']) + _d(m['remiseParrainage']),
      creditParrainage: _d(m['creditParrainage']),
      surcharges: _d(m['surcharges']),
      assurance: _d(m['assurance']),
      droitsDouane: _d(m['droitsDouane']),
      surDevis: j['surDevis'] as bool? ?? false,
      modeTarification: j['modeTarification'] as String? ?? 'poids',
      message: j['messageTarification'] as String?,
      dateLivraisonEstimee: delai['dateLivraisonEstimee'] as String?,
      delaiJours: delai['delaiJours'] as int?,
      poidsFactureKg: _d((j['poids'] as Map<String, dynamic>?)?['poidsFactureKg']),
      lignesForfait: (j['lignesForfait'] as List? ?? [])
          .map((l) => LigneDevis(
                libelle: l['libelle'] as String? ?? '',
                montant: _d(l['montant']),
                quantite: (l['quantite'] as num?)?.toInt() ?? 1,
                devise: l['devise'] as String?,
                prixAPartirDe: l['prixAPartirDe'] as bool? ?? false,
              ))
          .toList(),
      annexes: (j['detailAnnexes'] as List? ?? [])
          .map((l) => LigneDevis(libelle: l['libelle'] as String? ?? '', montant: _d(l['montant'])))
          .toList(),
      zoneTarifaire: corridor['zoneTarifaire'] as String?,
    );
  }

  @override
  List<Object?> get props => [service.id, total];
}

class ServiceIndisponible {
  final String serviceNom;
  final String motif;
  const ServiceIndisponible(this.serviceNom, this.motif);
}

class ResultatDevis {
  final List<OffreDevis> offres;
  final List<ServiceIndisponible> indisponibles;
  final double remiseParrainagePourcent;

  /// Simulation enregistrée par le backend, à renvoyer à la commande (mesure de conversion).
  final String? simulationId;
  const ResultatDevis({
    required this.offres,
    this.indisponibles = const [],
    this.remiseParrainagePourcent = 0,
    this.simulationId,
  });

  factory ResultatDevis.fromJson(Map<String, dynamic> j) => ResultatDevis(
        offres: (j['offres'] as List? ?? [])
            .map((o) => OffreDevis.fromJson(o as Map<String, dynamic>))
            .toList(),
        indisponibles: (j['servicesIndisponibles'] as List? ?? [])
            .map((s) => ServiceIndisponible(
                  (s['service'] as Map<String, dynamic>?)?['nom'] as String? ?? '',
                  s['motif'] as String? ?? '',
                ))
            .toList(),
        remiseParrainagePourcent: _d(j['remiseParrainagePourcent']),
        simulationId: j['simulationId'] as String?,
      );
}

/// Point de collecte ou de retrait proposé au client.
class PointService extends Equatable {
  final String id;
  final String nom;
  final String? adresse;
  final String? telephone;
  final String? villeNom;
  const PointService({required this.id, required this.nom, this.adresse, this.telephone, this.villeNom});

  factory PointService.fromJson(Map<String, dynamic> j) => PointService(
        id: j['id'] as String,
        nom: j['nom'] as String? ?? '',
        adresse: j['adresse'] as String?,
        telephone: j['telephone'] as String?,
        villeNom: (j['ville'] as Map<String, dynamic>?)?['nom'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

/// Ville desservie, avec l'indication de zone tarifaire Dakar.
class VilleDesservie extends Equatable {
  final String id;
  final String nom;
  final String pays;
  final bool zoneTarifDakar;
  final bool enlevementDomicile;
  final bool livraisonDomicile;
  const VilleDesservie({
    required this.id,
    required this.nom,
    required this.pays,
    this.zoneTarifDakar = false,
    this.enlevementDomicile = true,
    this.livraisonDomicile = true,
  });

  factory VilleDesservie.fromJson(Map<String, dynamic> j) => VilleDesservie(
        id: j['id'] as String,
        nom: j['nom'] as String? ?? '',
        pays: j['pays'] as String? ?? 'SN',
        zoneTarifDakar: j['zoneTarifDakar'] as bool? ?? false,
        enlevementDomicile: j['enlevementDomicileDisponible'] as bool? ?? true,
        livraisonDomicile: j['livraisonDomicileDisponible'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id];
}
