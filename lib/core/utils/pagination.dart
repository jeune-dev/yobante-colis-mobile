import 'package:dio/dio.dart';

/// Taille de page maximale acceptée par l'API.
const int kTaillePageMax = 100;

/// Charge toutes les pages d'une liste paginée du backend
/// (`data: { <cle>: [...], pagination: { totalPages, currentPage } }`).
///
/// Pour les écrans sans « charger plus » : sans cela, seuls les
/// [kTaillePageMax] premiers éléments étaient affichés. [maxPages] borne le
/// nombre d'appels.
Future<List<Map<String, dynamic>>> chargerToutesLesPages(
  Dio dio,
  String chemin,
  String cle, {
  Map<String, dynamic> parametres = const {},
  int maxPages = 20,
}) async {
  final elements = <Map<String, dynamic>>[];
  for (var page = 1; page <= maxPages; page++) {
    final res = await dio.get(chemin, queryParameters: {...parametres, 'page': page, 'limit': kTaillePageMax});
    final data = res.data['data'] as Map<String, dynamic>? ?? const {};
    elements.addAll((data[cle] as List? ?? const []).cast<Map<String, dynamic>>());
    final totalPages = ((data['pagination'] as Map?)?['totalPages'] as num?)?.toInt() ?? 1;
    if (page >= totalPages) break;
  }
  return elements;
}
