import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

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
  final double? latitude;
  final double? longitude;

  /// Distance depuis la position de l'utilisateur (recherche « autour de moi »).
  final double? distanceKm;

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
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  static double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

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
    latitude: _d(j['latitude']),
    longitude: _d(j['longitude']),
    distanceKm: _d(j['distanceKm']),
  );
}

/// Recherche de points de collecte/retrait Yobante Colis — façon DHL
/// (« Trouver un point de service »), accessible sans connexion.
class PointDeServicePage extends StatefulWidget {
  const PointDeServicePage({super.key});

  @override
  State<PointDeServicePage> createState() => _PointDeServicePageState();
}

class _PointDeServicePageState extends State<PointDeServicePage> {
  final _searchCtrl = TextEditingController();
  final _codePostalCtrl = TextEditingController();
  String _pays = 'SN';
  String? _service;
  String? _type;

  /// Position de l'utilisateur : la recherche se fait alors par proximité.
  Position? _position;
  double _rayonKm = 25;
  bool _localisation = false;
  bool _chargement = false;
  String? _erreur;
  List<_PointCollecte>? _resultats;

  static List<(String, String)> get _paysOptions => [('SN', tr('Sénégal')), ('FR', tr('France'))];

  static List<(String?, String)> get _serviceOptions => [
    (null, tr('Tous les services')),
    ('depot', tr('Dépôt de colis')),
    ('retrait', tr('Retrait de colis')),
    ('paiement', tr('Paiement')),
    ('emballage', tr('Emballage')),
    ('pesee', tr('Pesée')),
    ('declaration_douane', tr('Formalités douanières')),
  ];

  static List<(String?, String)> get _typeOptions => [
    (null, tr('Tous les points')),
    ('agence', tr('Agences')),
    ('point_relais', tr('Points relais')),
    ('casier', tr('Consignes')),
  ];

  static const _rayons = [5.0, 10.0, 25.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _rechercher();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _codePostalCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final position = _position;
      final params = <String, dynamic>{
        // Autour de moi : la position remplace le pays (le backend trie par distance)
        if (position == null) 'pays': _pays,
        if (position != null) ...{'latitude': position.latitude, 'longitude': position.longitude, 'rayonKm': _rayonKm},
        if (position == null && _pays == 'FR' && _codePostalCtrl.text.trim().isNotEmpty)
          'codePostal': _codePostalCtrl.text.trim(),
        'service': ?_service,
        'type': ?_type,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      };
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

  /// Active la recherche par proximité (autorisation de localisation demandée).
  Future<void> _autourDeMoi() async {
    if (_position != null) {
      setState(() => _position = null);
      return _rechercher();
    }
    setState(() => _localisation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(tr('Activez la localisation de votre téléphone.'));
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception(tr('Autorisez l\'accès à votre position pour trouver les points proches.'));
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      setState(() => _position = position);
      await _rechercher();
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _localisation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultats = _resultats ?? const <_PointCollecte>[];
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(leading: const BoutonMenuOuRetour(), title: Text(tr('Point de service'))),
      // Un seul défilement : filtres compacts en tête, puis la liste des points
      body: RefreshIndicator(
        onRefresh: _rechercher,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _filtres()),
            if (_chargement && _resultats == null)
              const SliverFillRemaining(hasScrollBody: true, child: ShimmerList(itemCount: 3))
            else if (_erreur != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: tr('Erreur'),
                  subtitle: _erreur!,
                  actionLabel: tr('Réessayer'),
                  onAction: _rechercher,
                  scrollable: false,
                ),
              )
            else if (resultats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.storefront_outlined,
                  title: tr('Aucun point trouvé'),
                  subtitle: tr('Essayez une autre ville ou élargissez votre recherche.'),
                  scrollable: false,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    resultats.length > 1 ? tr('${resultats.length} points trouvés') : tr('1 point trouvé'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: resultats.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PointCard(point: resultats[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Champ de saisie sur fond clair, sans le cadre imposé par le thème des formulaires.
  InputDecoration _decorationChamp(String indication, IconData icone, {Widget? suffixe}) => InputDecoration(
    hintText: indication,
    prefixIcon: Icon(icone, color: AppColor.kPrimary, size: 20),
    suffixIcon: suffixe,
    filled: true,
    fillColor: AppColor.kBackground,
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.2),
    ),
  );

  /// Rangée de puces sur une seule ligne, défilant horizontalement.
  Widget _rangeePuces<T>(List<(T, String)> options, T valeur, ValueChanged<T> choisir) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final (code, libelle) = options[i];
        final choisi = code == valeur;
        return ChoiceChip(
          label: Text(libelle),
          selected: choisi,
          showCheckmark: false,
          selectedColor: AppColor.kPrimary,
          backgroundColor: AppColor.kWhite,
          side: BorderSide(color: choisi ? AppColor.kPrimary : AppColor.kLine),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: choisi ? AppColor.kWhite : AppColor.kPrimary,
          ),
          visualDensity: VisualDensity.compact,
          onSelected: (_) {
            choisir(code);
            _rechercher();
          },
        );
      },
    ),
  );

  Widget _filtres() {
    return Container(
      color: AppColor.kWhite,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Pays et recherche sur la même ligne
                Row(
                  children: [
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _position == null ? _pays : null,
                          hint: const Icon(Icons.near_me_rounded, color: AppColor.kPrimary, size: 18),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.kPrimary),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                          items: _paysOptions.map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2))).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _pays = v;
                              _position = null;
                            });
                            _rechercher();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _rechercher(),
                        decoration: _decorationChamp(
                          tr('Ville, quartier…'),
                          Icons.search_rounded,
                          suffixe: IconButton(
                            tooltip: tr('Rechercher'),
                            icon: const Icon(Icons.arrow_forward_rounded, color: AppColor.kPrimary, size: 20),
                            onPressed: _chargement ? null : _rechercher,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_position == null && _pays == 'FR') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codePostalCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _rechercher(),
                    decoration: _decorationChamp(tr('Code postal'), Icons.markunread_mailbox_outlined),
                  ),
                ],
                const SizedBox(height: 8),
                // Autour de moi : bouton compact, rayon à côté une fois activé
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _localisation ? null : _autourDeMoi,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColor.kPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _localisation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_position == null ? Icons.my_location : Icons.location_off_outlined, size: 18),
                        label: Text(
                          _position == null ? tr('Autour de moi') : tr('Quitter « autour de moi »'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (_position != null) ...[
                      const SizedBox(width: 8),
                      DropdownButton<double>(
                        value: _rayonKm,
                        underline: const SizedBox.shrink(),
                        items: _rayons
                            .map((r) => DropdownMenuItem(value: r, child: Text(tr('${r.toStringAsFixed(0)} km'))))
                            .toList(),
                        onChanged: (r) {
                          if (r == null) return;
                          setState(() => _rayonKm = r);
                          _rechercher();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _rangeePuces<String?>(_typeOptions, _type, (v) => setState(() => _type = v)),
          const SizedBox(height: 6),
          _rangeePuces<String?>(_serviceOptions, _service, (v) => setState(() => _service = v)),
          if (_chargement && _resultats != null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2, color: AppColor.kPrimary),
            ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final _PointCollecte point;
  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColor.kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, color: AppColor.kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      point.typeLibelle,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (point.ouvertMaintenant ? AppColor.kSucces : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  point.ouvertMaintenant ? tr('Ouvert') : tr('Fermé'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: point.ouvertMaintenant ? AppColor.kSucces : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColor.kGrayscale40),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [point.adresse, point.quartier, point.villeNom].where((e) => e != null && e.isNotEmpty).join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscaleDark100),
                ),
              ),
              if (point.distanceKm != null) ...[
                const SizedBox(width: 8),
                Text(
                  tr('${point.distanceKm!.toStringAsFixed(1)} km'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
              ],
            ],
          ),
          if ((point.telephone?.isNotEmpty ?? false) || (point.latitude != null && point.longitude != null)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (point.telephone?.isNotEmpty ?? false)
                  InkWell(
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: point.telephone)),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColor.kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            point.telephone!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColor.kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (point.latitude != null && point.longitude != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: Text(
                      tr('Itinéraire'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
