import 'package:flutter/material.dart';
import '../i18n/langue.dart';

/// Les trois catégories de colis du cahier des charges, avec les règles de
/// parcours appliquées par le backend. Les valeurs intégrées servent de repli :
/// au démarrage, les règles sont relues sur `GET /public/categories`
/// ([appliquerRegles]) pour suivre ce que le backend impose réellement.
class CategorieColis {
  final String code;
  final int numero;
  /// Textes en français (valeurs intégrées ou envoyées par le backend) ;
  /// [libelle], [description] et [exemples] les renvoient dans la langue choisie.
  final String libelleFr;
  final String descriptionFr;
  final String exemplesFr;

  String get libelle => tr(libelleFr);
  String get description => tr(descriptionFr);
  String get exemples => tr(exemplesFr);
  final IconData icone;

  /// Prix fixe (grille) ou défini par l'administrateur après étude.
  final bool surDevis;
  final bool validationAdmin;

  /// `a_la_commande`, `a_la_reception` ou `apres_acceptation`.
  final String paiement;
  final int photosMin;
  final List<String> modesDepot;

  /// Quartier, arrondissement, département et point de repère obligatoires au Sénégal.
  final bool adresseSenegalDetaillee;

  const CategorieColis({
    required this.code,
    required this.numero,
    required String libelle,
    required String description,
    required String exemples,
    required this.icone,
    required this.surDevis,
    required this.validationAdmin,
    required this.paiement,
    required this.photosMin,
    required this.modesDepot,
    required this.adresseSenegalDetaillee,
  }) : libelleFr = libelle,
       descriptionFr = description,
       exemplesFr = exemples;

  String get parcours => switch (paiement) {
        'a_la_commande' => tr('Prix fixe · paiement immédiat'),
        'a_la_reception' => tr('Prix fixe · validation sous 24 h · paiement à la réception du colis'),
        _ => tr('Prix proposé sous 24 h · paiement après acceptation'),
      };

  static const _documents = CategorieColis(
    code: 'documents',
    numero: 1,
    libelle: 'Documents',
    description: 'Documents administratifs sous enveloppe',
    exemples: 'Actes, diplômes, courriers',
    icone: Icons.mail_outline_rounded,
    surDevis: false,
    validationAdmin: false,
    paiement: 'a_la_commande',
    photosMin: 1,
    modesDepot: ['point_collecte', 'envoi_postal', 'boite_aux_lettres'],
    adresseSenegalDetaillee: false,
  );

  static const _colisMoyen = CategorieColis(
    code: 'colis_moyen',
    numero: 2,
    libelle: 'Colis moyen',
    description: 'Valises, sacs, barigots, électronique',
    exemples: 'Smartphones, ordinateurs, petit électroménager',
    icone: Icons.inventory_2_outlined,
    surDevis: false,
    validationAdmin: true,
    paiement: 'a_la_reception',
    photosMin: 3,
    modesDepot: ['point_collecte', 'enlevement_domicile', 'envoi_postal', 'boite_aux_lettres'],
    adresseSenegalDetaillee: true,
  );

  static const _colisXxl = CategorieColis(
    code: 'colis_xxl',
    numero: 3,
    libelle: 'Colis XXL',
    description: 'Gros volumes de plus de 30 kg',
    exemples: 'Réfrigérateurs, machines, gros cartons',
    icone: Icons.kitchen_outlined,
    surDevis: true,
    validationAdmin: true,
    paiement: 'apres_acceptation',
    photosMin: 1,
    modesDepot: ['point_collecte', 'enlevement_domicile'],
    adresseSenegalDetaillee: true,
  );

  static List<CategorieColis> _toutes = const [_documents, _colisMoyen, _colisXxl];

  static List<CategorieColis> get toutes => _toutes;
  static CategorieColis get documents => parCode('documents');
  static CategorieColis get colisMoyen => parCode('colis_moyen');
  static CategorieColis get colisXxl => parCode('colis_xxl');

  static CategorieColis parCode(String? code) => _toutes.firstWhere(
        (c) => c.code == code,
        orElse: () => _toutes.firstWhere((c) => c.code == 'colis_moyen', orElse: () => _colisMoyen),
      );

  /// Remplace les règles intégrées par celles du backend (`data.categories`),
  /// en conservant l'icône et les exemples propres à l'application.
  static void appliquerRegles(List<dynamic> categories) {
    final lues = <CategorieColis>[];
    for (final brut in categories) {
      if (brut is! Map) continue;
      final code = brut['code'] as String?;
      if (code == null) continue;
      final local = const [_documents, _colisMoyen, _colisXxl]
          .where((c) => c.code == code)
          .firstOrNull;
      lues.add(CategorieColis(
        code: code,
        numero: (brut['numero'] as num?)?.toInt() ?? local?.numero ?? lues.length + 1,
        libelle: brut['libelle'] as String? ?? local?.libelleFr ?? code,
        description: brut['description'] as String? ?? local?.descriptionFr ?? '',
        exemples: local?.exemplesFr ?? '',
        icone: local?.icone ?? Icons.inventory_2_outlined,
        surDevis: brut['tarification'] == 'sur_devis',
        validationAdmin: brut['validationAdmin'] as bool? ?? local?.validationAdmin ?? true,
        paiement: brut['paiement'] as String? ?? local?.paiement ?? 'a_la_reception',
        photosMin: (brut['photosMin'] as num?)?.toInt() ?? local?.photosMin ?? 1,
        modesDepot: (brut['modesDepot'] as List?)?.map((m) => '$m').toList() ?? local?.modesDepot ?? const [],
        adresseSenegalDetaillee: brut['adresseSenegalDetaillee'] as bool? ?? local?.adresseSenegalDetaillee ?? false,
      ));
    }
    if (lues.isNotEmpty) {
      lues.sort((a, b) => a.numero.compareTo(b.numero));
      _toutes = List.unmodifiable(lues);
    }
  }
}

/// Libellés des modes de remise du colis, dans la langue choisie.
Map<String, String> get libellesModeDepot => {
      for (final e in _libellesModeDepotFr.entries) e.key: tr(e.value),
    };

const _libellesModeDepotFr = {
  'point_collecte': 'Dépôt en point de collecte',
  'enlevement_domicile': 'Collecte à domicile',
  'envoi_postal': 'Envoi par la poste',
  'boite_aux_lettres': 'Collecte en boîte aux lettres',
};

const iconesModeDepot = {
  'point_collecte': Icons.storefront_outlined,
  'enlevement_domicile': Icons.home_work_outlined,
  'envoi_postal': Icons.local_post_office_outlined,
  'boite_aux_lettres': Icons.markunread_mailbox_outlined,
};
