import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/routes/app_shell_key.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../../core/i18n/langue.dart';

class _PointCollecte {
  final String id;
  final String nom;
  final String typeLibelle;
  final String? villeNom;
  final String adresse;
  final String? quartier;
  final String? telephone;
  final List<String> services;
  final bool ouvertMaintenant;

  const _PointCollecte({
    required this.id,
    required this.nom,
    required this.typeLibelle,
    this.villeNom,
    required this.adresse,
    this.quartier,
    this.telephone,
    required this.services,
    required this.ouvertMaintenant,
  });

  factory _PointCollecte.fromJson(Map<String, dynamic> j) => _PointCollecte(
        id: j['id'] as String,
        nom: j['nom'] as String? ?? '',
        typeLibelle: j['typeLibelle'] as String? ?? tr('Agence'),
        villeNom: (j['ville'] as Map<String, dynamic>?)?['nom'] as String?,
        adresse: j['adresse'] as String? ?? '',
        quartier: j['quartier'] as String?,
        telephone: j['telephone'] as String?,
        services: (j['services'] as List? ?? []).map((e) => e.toString()).toList(),
        ouvertMaintenant: j['ouvertMaintenant'] as bool? ?? false,
      );
}

/// Recherche de points de collecte/retrait Yobante Express — façon DHL
/// (« Trouver un point de service »), accessible sans connexion.
class PointDeServicePage extends StatefulWidget {
  const PointDeServicePage({super.key});

  @override
  State<PointDeServicePage> createState() => _PointDeServicePageState();
}

class _PointDeServicePageState extends State<PointDeServicePage> {
  final _searchCtrl = TextEditingController();
  String _pays = 'SN';
  String? _service;
  bool _chargement = false;
  String? _erreur;
  List<_PointCollecte>? _resultats;

  static List<(String, String)> get _paysOptions => [
    ('SN', tr('Sénégal')),
    ('FR', tr('France')),
  ];

  static List<(String?, String)> get _serviceOptions => [
    (null, tr('Tous les services')),
    ('depot', tr('Dépôt de colis')),
    ('retrait', tr('Retrait de colis')),
  ];

  @override
  void initState() {
    super.initState();
    _rechercher();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final params = <String, dynamic>{'pays': _pays};
      if (_service != null) params['service'] = _service;
      if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();
      final res = await sl<Dio>().get(Env.publicPointsCollecte, queryParameters: params);
      final list = (res.data['data']['points'] as List)
          .map((e) => _PointCollecte.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _resultats = list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e, tr('Erreur lors de la recherche.')));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(tr('Point de service')),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColor.kWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Sélectionner votre position'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColor.kGrayscale40)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _pays,
                            items: _paysOptions
                                .map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2)))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _pays = v);
                              _rechercher();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _rechercher(),
                    decoration: InputDecoration(
                      hintText: tr('Ville, quartier ou adresse'),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, color: AppColor.kGrayscale40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr('Sélectionnez un service'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColor.kGrayscale40)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _serviceOptions.map((s) {
                    final selected = _service == s.$1;
                    return ChoiceChip(
                      label: Text(s.$2, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      selectedColor: AppColor.kSecondary,
                      onSelected: (_) {
                        setState(() => _service = s.$1);
                        _rechercher();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _rechercher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      foregroundColor: AppColor.kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr('Rechercher'), style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResultats()),
        ],
      ),
    );
  }

  Widget _buildResultats() {
    if (_chargement && _resultats == null) return const ShimmerList();
    if (_erreur != null) {
      return EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!, actionLabel: tr('Réessayer'), onAction: _rechercher);
    }
    final resultats = _resultats ?? [];
    if (resultats.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: tr('Aucun point trouvé'),
        subtitle: tr('Essayez une autre ville ou élargissez votre recherche.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: resultats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PointCard(point: resultats[i]),
    );
  }
}

class _PointCard extends StatelessWidget {
  final _PointCollecte point;
  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColor.kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, color: AppColor.kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(point.nom, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(point.typeLibelle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (point.ouvertMaintenant ? AppColor.kSucces : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(point.ouvertMaintenant ? tr('Ouvert') : tr('Fermé'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: point.ouvertMaintenant ? AppColor.kSucces : Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColor.kGrayscale40),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                [point.adresse, point.quartier, point.villeNom].where((e) => e != null && e.isNotEmpty).join(', '),
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
            ),
          ]),
          if (point.telephone != null && point.telephone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: point.telephone)),
              child: Row(children: [
                const Icon(Icons.phone_outlined, size: 14, color: AppColor.kPrimary),
                const SizedBox(width: 6),
                Text(point.telephone!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kPrimary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
