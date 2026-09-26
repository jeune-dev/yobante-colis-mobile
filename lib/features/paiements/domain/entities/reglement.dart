import 'package:equatable/equatable.dart';
import '../../../../core/i18n/langue.dart';

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

Map<String, String> get kLibellesMethodePaiement => {
  'wave': tr('Wave'),
  'orange_money': tr('Orange Money'),
  'free_money': tr('Free Money'),
  'carte': tr('Carte bancaire'),
  'virement': tr('Virement'),
  'especes': tr('Espèces'),
  'paypal': tr('PayPal'),
};

Map<String, String> get kLibellesStatutPaiement => {
  'en_attente': tr('En attente'),
  'succes': tr('Réussi'),
  'echoue': tr('Échoué'),
  'rembourse': tr('Remboursé'),
  'partiel': tr('Partiel'),
};

/// Règlement enregistré sur une facture (`GET /client/paiements`).
class Reglement extends Equatable {
  final String id;
  final String reference;
  final double montant;
  final String devise;
  final String methode;
  final String statut;
  final String? factureReference;
  final DateTime date;

  const Reglement({
    required this.id,
    required this.reference,
    required this.montant,
    required this.devise,
    required this.methode,
    required this.statut,
    this.factureReference,
    required this.date,
  });

  String get methodeLibelle => kLibellesMethodePaiement[methode] ?? methode;
  String get statutLibelle => kLibellesStatutPaiement[statut] ?? statut;

  factory Reglement.fromJson(Map<String, dynamic> j) => Reglement(
        id: j['id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        montant: _d(j['montant']),
        devise: j['devise'] as String? ?? 'XOF',
        methode: j['methode'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        factureReference: (j['facture'] as Map<String, dynamic>?)?['reference'] as String?,
        date: DateTime.tryParse((j['payeAt'] ?? j['createdAt'] ?? '') as String) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, statut];
}

/// Récapitulatif des sommes dues (`GET /client/paiements/encours`).
class Encours {
  final int nbFacturesImpayees;
  final Map<String, double> parDevise;
  final int nbFacturesEchues;

  const Encours({this.nbFacturesImpayees = 0, this.parDevise = const {}, this.nbFacturesEchues = 0});

  factory Encours.fromJson(Map<String, dynamic> j) => Encours(
        nbFacturesImpayees: (j['nbFacturesImpayees'] as num?)?.toInt() ?? 0,
        parDevise: (j['parDevise'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, _d(v))),
        nbFacturesEchues: (j['facturesEchues'] as List? ?? const []).length,
      );
}
