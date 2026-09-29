import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../../features/colis/domain/entities/colis.dart';
import '../../features/colis/domain/entities/demande_expedition.dart';
import '../../features/colis/domain/repositories/colis_repository.dart';
import '../../features/villes/domain/entities/ville.dart';
import 'demo_data.dart';
import '../types/avec_message.dart';

/// Implémentation locale de [ColisRepository] pour le mode démo
/// (voir demo_config.dart) — aucune requête réseau, données en mémoire.
class DemoColisRepository implements ColisRepository {
  static const _statutsOrdre = ['en_attente', 'en_preparation', 'en_transit', 'arrive', 'disponible_retrait', 'livre'];

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColis({String? statut, int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final filtered = statut == null || statut.isEmpty
        ? DemoData.colis
        : DemoData.colis.where((c) => c.statut == statut).toList();
    return Right({
      'colis': List<Colis>.from(filtered),
      'pagination': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getColisRecus({String? statut, int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Pas de notion de destinataire-compte en mode démo : rien à recevoir.
    return const Right({
      'colis': <Colis>[],
      'pagination': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
    });
  }

  @override
  Future<Either<Failure, Colis>> getColisDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final colis = _findColis(id);
    if (colis == null) return const Left(ServerFailure('Colis introuvable'));
    return Right(colis);
  }

  @override
  Future<Either<Failure, ResultatDeclaration>> creerColis(
    DemandeExpedition demande, {
    List<String> photosPaths = const [],
    void Function(int, int)? onSendProgress,
  }) async {
    onSendProgress?.call(50, 100);
    await Future.delayed(const Duration(milliseconds: 700));
    onSendProgress?.call(100, 100);

    final villeDepart = _findVille(demande.villeDepartId);
    final villeArrivee = _findVille(demande.villeArriveeId);
    final poids = demande.poidsKg ??
        demande.pieces.fold<double>(0, (acc, p) => acc + p.poidsKg) +
            demande.articles.fold<double>(0, (acc, a) => acc + a.quantite * 10);
    final montant = demande.categorie == 'colis_xxl' ? 0.0 : _tarifIndicatif(poids);

    final nouveau = Colis(
      id: 'demo-colis-${DateTime.now().millisecondsSinceEpoch}',
      reference: 'PNCO01${DateTime.now().day.toString().padLeft(2, '0')}092026DEM0${demande.categorie == 'documents' ? 1 : demande.categorie == 'colis_moyen' ? 2 : 3}',
      serviceId: demande.serviceId,
      categorie: demande.categorie,
      expediteurNom: demande.expediteurNom,
      expediteurTelephone: demande.expediteurTelephone,
      paysDepart: villeDepart?.pays ?? 'FR',
      villeDepartId: demande.villeDepartId,
      villeDepart: villeDepart != null ? VilleRef(id: villeDepart.id, nom: villeDepart.nom, pays: villeDepart.pays) : null,
      adresseDepart: demande.adresseDepart,
      destinataireNom: demande.destinataireNom,
      destinataireTelephone: demande.destinataireTelephone,
      paysArrivee: villeArrivee?.pays ?? 'SN',
      villeArriveeId: demande.villeArriveeId,
      villeArrivee: villeArrivee != null ? VilleRef(id: villeArrivee.id, nom: villeArrivee.nom, pays: villeArrivee.pays) : null,
      adresseLivraison: demande.adresseLivraison,
      description: demande.description,
      modeDepot: demande.modeDepot,
      modeLivraison: demande.modeLivraison,
      poidsFactureKg: poids,
      valeurDeclaree: demande.valeurDeclaree,
      montantTotal: montant,
      devise: 'EUR',
      statut: demande.categorie == 'documents' ? 'en_attente' : 'en_attente_validation',
      photos: const [],
      createdAt: DateTime.now(),
    );
    DemoData.colis.insert(0, nouveau);

    return Right(ResultatDeclaration(
      colis: nouveau,
      message: demande.categorie == 'documents'
          ? 'Expédition enregistrée avec succès.'
          : 'Demande enregistrée. Nos équipes l\'étudient sous 24 h.',
    ));
  }

  @override
  Future<Either<Failure, ResultatDeclaration>> accepterProposition(String id) async {
    final colis = _findColis(id);
    if (colis == null) return const Left(ServerFailure('Colis introuvable'));
    return Right(ResultatDeclaration(colis: colis, message: 'Proposition acceptée.'));
  }

  @override
  Future<Either<Failure, AvecMessage<Colis>>> refuserProposition(String id, {String? motif}) async {
    final colis = _findColis(id);
    if (colis == null) return const Left(ServerFailure('Colis introuvable'));
    return Right((valeur: colis, message: 'Proposition déclinée. Votre demande est clôturée.'));
  }

  @override
  Future<Either<Failure, AvecMessage<Colis>>> modifierColis(String id, Map<String, dynamic> champs) async {
    final colis = _findColis(id);
    if (colis == null) return const Left(ServerFailure('Colis introuvable'));
    return Right((valeur: colis, message: 'Votre demande a été mise à jour.'));
  }

  @override
  Future<Either<Failure, List<SuiviEvenement>>> getSuiviColis(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final colis = _findColis(id);
    if (colis == null) return const Left(ServerFailure('Colis introuvable'));

    if (colis.statut == 'annule') {
      return Right([
        SuiviEvenement(
          statut: 'en_attente', libelle: 'Colis enregistré',
          lieu: colis.villeDepart?.nom, date: colis.createdAt,
        ),
        SuiviEvenement(
          statut: 'annule', libelle: colis.annuleMotif ?? 'Colis annulé',
          lieu: colis.villeDepart?.nom, date: colis.createdAt.add(const Duration(hours: 2)),
        ),
      ]);
    }

    final indexActuel = _statutsOrdre.indexOf(colis.statut);
    final etapes = <SuiviEvenement>[];
    for (var i = 0; i <= indexActuel && i < _statutsOrdre.length; i++) {
      etapes.add(SuiviEvenement(
        statut: _statutsOrdre[i],
        libelle: _libellePourStatut(_statutsOrdre[i]),
        lieu: i == 0 ? colis.villeDepart?.nom : (i == indexActuel ? colis.villeArrivee?.nom : null),
        date: colis.createdAt.add(Duration(hours: i * 6)),
      ));
    }
    return Right(etapes.reversed.toList());
  }

  @override
  Future<Either<Failure, AvecMessage<Colis>>> annulerColis(String id, {String? motif}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = DemoData.colis.indexWhere((c) => c.id == id);
    if (index == -1) return const Left(ServerFailure('Colis introuvable'));
    final ancien = DemoData.colis[index];
    final annule = Colis(
      id: ancien.id, reference: ancien.reference, serviceId: ancien.serviceId, service: ancien.service,
      typeContenu: ancien.typeContenu, fragile: ancien.fragile,
      expediteurNom: ancien.expediteurNom, expediteurTelephone: ancien.expediteurTelephone,
      paysDepart: ancien.paysDepart, villeDepartId: ancien.villeDepartId, villeDepart: ancien.villeDepart,
      adresseDepart: ancien.adresseDepart,
      destinataireNom: ancien.destinataireNom, destinataireTelephone: ancien.destinataireTelephone,
      paysArrivee: ancien.paysArrivee, villeArriveeId: ancien.villeArriveeId, villeArrivee: ancien.villeArrivee,
      adresseLivraison: ancien.adresseLivraison,
      poidsFactureKg: ancien.poidsFactureKg, valeurDeclaree: ancien.valeurDeclaree,
      montantTotal: ancien.montantTotal, statut: 'annule', photos: ancien.photos,
      annuleMotif: motif ?? 'Annulé par le client', createdAt: ancien.createdAt,
    );
    DemoData.colis[index] = annule;
    return Right((valeur: annule, message: 'Expédition annulée.'));
  }

  Colis? _findColis(String id) {
    for (final c in DemoData.colis) {
      if (c.id == id) return c;
    }
    return null;
  }

  Ville? _findVille(String id) {
    for (final v in DemoData.villes) {
      if (v.id == id) return v;
    }
    return null;
  }

  double _tarifIndicatif(double poids) => (1500 + poids * 700).roundToDouble();

  String _libellePourStatut(String statut) {
    switch (statut) {
      case 'en_attente':          return 'Colis enregistré';
      case 'en_preparation':      return 'Colis en préparation à l\'agence';
      case 'en_transit':          return 'Colis en cours d\'acheminement';
      case 'arrive':              return 'Colis arrivé à destination';
      case 'disponible_retrait':  return 'Disponible au point de retrait';
      case 'livre':               return 'Colis livré au destinataire';
      default:                    return '';
    }
  }
}
