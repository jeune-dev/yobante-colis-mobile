import 'package:equatable/equatable.dart';

/// Filtres des listes de colis, appliqués par le backend (`GET /client/colis`
/// et `GET /client/colis/recus`). Le statut reste un paramètre à part.
///
/// Les colis reçus n'acceptent que la période ([dateDebut], [dateFin]).
class FiltresColis extends Equatable {
  /// Recherche partielle sur la référence (insensible à la casse).
  final String? reference;
  final String? categorie;

  /// Uniquement les expéditions non terminées.
  final bool enCours;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const FiltresColis({this.reference, this.categorie, this.enCours = false, this.dateDebut, this.dateFin});

  static String _jour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Paramètres de requête ; [recus] limite aux filtres acceptés pour les colis reçus.
  Map<String, dynamic> versRequete({bool recus = false}) => {
        if (!recus && reference != null && reference!.trim().isNotEmpty) 'reference': reference!.trim(),
        if (!recus && categorie != null) 'categorie': categorie,
        if (!recus && enCours) 'enCours': 'true',
        if (dateDebut != null) 'dateDebut': _jour(dateDebut!),
        // Fin de journée incluse : le backend compare la date de création à cet instant
        if (dateFin != null) 'dateFin': '${_jour(dateFin!)}T23:59:59',
      };

  bool get actif =>
      (reference?.trim().isNotEmpty ?? false) || categorie != null || enCours || dateDebut != null || dateFin != null;

  FiltresColis copyWith({
    String? reference,
    String? categorie,
    bool? enCours,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool effacerCategorie = false,
    bool effacerPeriode = false,
  }) =>
      FiltresColis(
        reference: reference ?? this.reference,
        categorie: effacerCategorie ? null : categorie ?? this.categorie,
        enCours: enCours ?? this.enCours,
        dateDebut: effacerPeriode ? null : dateDebut ?? this.dateDebut,
        dateFin: effacerPeriode ? null : dateFin ?? this.dateFin,
      );

  @override
  List<Object?> get props => [reference, categorie, enCours, dateDebut, dateFin];
}
