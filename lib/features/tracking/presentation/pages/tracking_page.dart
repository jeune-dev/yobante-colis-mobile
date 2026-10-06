import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../../../core/i18n/langue.dart';

class _EvenementSuivi {
  final String code;
  final String libelle;
  final String? lieu;
  final String? date;
  const _EvenementSuivi({required this.code, required this.libelle, this.lieu, this.date});

  factory _EvenementSuivi.fromJson(Map<String, dynamic> j) => _EvenementSuivi(
        code: j['code'] as String? ?? '',
        libelle: j['libelle'] as String? ?? '',
        lieu: j['lieu'] as String?,
        date: j['date'] as String?,
      );
}

class _SuiviPublic {
  final String reference;
  final String statut;
  final String statutLibelle;
  final String? villeOrigine;
  final String? villeDestination;
  final String? dateLivraisonEstimee;
  final List<_EvenementSuivi> historique;
  const _SuiviPublic({
    required this.reference,
    required this.statut,
    required this.statutLibelle,
    this.villeOrigine,
    this.villeDestination,
    this.dateLivraisonEstimee,
    required this.historique,
  });

  factory _SuiviPublic.fromJson(Map<String, dynamic> j) => _SuiviPublic(
        reference: j['reference'] as String,
        statut: j['statut'] as String? ?? '',
        statutLibelle: j['statutLibelle'] as String? ?? '',
        villeOrigine: j['origine']?['ville'] as String?,
        villeDestination: j['destination']?['ville'] as String?,
        dateLivraisonEstimee: j['dateLivraisonEstimee'] as String?,
        historique: (j['historique'] as List? ?? [])
            .map((e) => _EvenementSuivi.fromJson(e as Map<String, dynamic>))
            .toList()
            .reversed
            .toList(),
      );
}

/// Page autonome reprenant [TrackingSearch], accessible depuis le tiroir
/// latéral (« Suivre ») indépendamment de l'onglet Accueil.
class TrackingPage extends StatelessWidget {
  /// Numéro de suivi recherché dès l'ouverture (colis reçu, lien partagé…).
  final String? reference;
  const TrackingPage({super.key, this.reference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Suivre un colis'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: TrackingSearch(referenceInitiale: reference),
      ),
    );
  }
}

/// Recherche de suivi par numéro de référence, sans connexion — façon DHL
/// ("Track a shipment" en accès libre depuis l'accueil).
class TrackingSearch extends StatefulWidget {
  final String? referenceInitiale;
  const TrackingSearch({super.key, this.referenceInitiale});

  @override
  State<TrackingSearch> createState() => _TrackingSearchState();
}

class _TrackingSearchState extends State<TrackingSearch> {
  final _refCtrl = TextEditingController();
  bool _chargement = false;
  String? _erreur;
  _SuiviPublic? _resultat;

  @override
  void initState() {
    super.initState();
    final ref = widget.referenceInitiale;
    if (ref != null && ref.isNotEmpty) {
      _refCtrl.text = ref;
      WidgetsBinding.instance.addPostFrameCallback((_) => _rechercher());
    }
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) return;
    // Numéro de suivi : 3 à 40 caractères (contrôle du backend)
    if (ref.length < 3) {
      setState(() => _erreur = tr('Numéro de suivi trop court.'));
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
      _resultat = null;
    });
    try {
      final res = await sl<Dio>().get(Env.publicSuivi(ref));
      if (!mounted) return;
      setState(() => _resultat = _SuiviPublic.fromJson(res.data['data']['suivi'] as Map<String, dynamic>));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e, tr('Aucune expédition trouvée pour ce numéro.')));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre de recherche : une seule zone blanche, champ sans cadre propre
        // (le thème des formulaires est neutralisé ici) et bouton bleu marine,
        // bien visible sur le bandeau jaune de l'accueil.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColor.kPrimary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _refCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  onSubmitted: (_) => _rechercher(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('N° de suivi'),
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _chargement ? null : _rechercher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimary,
                  foregroundColor: AppColor.kWhite,
                  disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.6),
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _chargement
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.kWhite))
                    : Text(tr('Suivre'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(tr('Exemple : PNCO2610060001ADI01'),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kPrimary.withValues(alpha: 0.7))),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(_erreur!, style: GoogleFonts.plusJakartaSans(color: AppColor.kErreur, fontSize: 13)),
        ],
        if (_resultat != null) ...[
          const SizedBox(height: 16),
          _ResultatSuivi(suivi: _resultat!),
        ],
      ],
    );
  }
}

class _ResultatSuivi extends StatelessWidget {
  final _SuiviPublic suivi;
  const _ResultatSuivi({required this.suivi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(suivi.reference,
                    style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(20)),
                child: Text(tr(suivi.statutLibelle),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
              ),
            ],
          ),
          if (suivi.villeOrigine != null && suivi.villeDestination != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(suivi.villeOrigine!, style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColor.kWhite, size: 16),
                ),
                Text(suivi.villeDestination!, style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontSize: 13)),
              ],
            ),
          ],
          if (suivi.dateLivraisonEstimee != null) ...[
            const SizedBox(height: 6),
            Text(tr('Livraison estimée : ${suivi.dateLivraisonEstimee}'),
                style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite.withValues(alpha: 0.75), fontSize: 12)),
          ],
          if (suivi.historique.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColor.kWhite.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            ...suivi.historique.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(e.libelle),
                                style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                            if (e.lieu != null)
                              Text(e.lieu!,
                                  style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite.withValues(alpha: 0.7), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
