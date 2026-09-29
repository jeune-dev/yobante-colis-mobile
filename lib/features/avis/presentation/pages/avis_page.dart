import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/avis_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';

/// Formulaire de dépôt d'un avis (après livraison si [colisId] est fourni).
/// Renvoie `true` si l'avis a été enregistré.
Future<bool> donnerAvis(BuildContext context, {String? colisId, String? colisReference}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _FormulaireAvis(colisId: colisId, colisReference: colisReference),
  );
  return ok == true;
}

class _FormulaireAvis extends StatefulWidget {
  final String? colisId;
  final String? colisReference;
  const _FormulaireAvis({this.colisId, this.colisReference});

  @override
  State<_FormulaireAvis> createState() => _FormulaireAvisState();
}

class _FormulaireAvisState extends State<_FormulaireAvis> {
  final _titre = TextEditingController();
  final _commentaire = TextEditingController();
  int _note = 0;
  bool _envoi = false;

  @override
  void dispose() {
    _titre.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_note == 0) {
      showToast(context, tr('Note requise'), tr('Choisissez une note de 1 à 5 étoiles.'), ToastificationType.warning);
      return;
    }
    setState(() => _envoi = true);
    try {
      final message = await sl<AvisRemoteDataSource>().deposer(
        note: _note,
        titre: _titre.text,
        commentaire: _commentaire.text,
        colisId: widget.colisId,
      );
      if (!mounted) return;
      showToast(context, tr('Merci !'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Votre avis'), style: titreSection(18)),
        if (widget.colisReference != null) Text(tr('Expédition ${widget.colisReference}'), style: texteDiscret(13)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              onPressed: () => setState(() => _note = i),
              icon: Icon(_note >= i ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 38, color: AppColor.kSecondary),
            ),
        ]),
        TextField(
          controller: _titre,
          maxLength: 120,
          decoration: InputDecoration(labelText: tr('Titre (facultatif)'), counterText: ''),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentaire,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(labelText: tr('Votre commentaire (facultatif)')),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _envoi ? null : _envoyer,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _envoi
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(tr('Publier mon avis')),
        ),
      ]),
    );
  }
}

class _Etoiles extends StatelessWidget {
  final num note;
  final double taille;
  const _Etoiles(this.note, {this.taille = 16});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            note >= i ? Icons.star_rounded : (note >= i - 0.5 ? Icons.star_half_rounded : Icons.star_border_rounded),
            size: taille,
            color: AppColor.kSecondary,
          ),
      ]);
}

/// Avis publiés par les clients et, pour un client connecté, ses propres avis.
class AvisPage extends StatefulWidget {
  const AvisPage({super.key});

  @override
  State<AvisPage> createState() => _AvisPageState();
}

class _AvisPageState extends State<AvisPage> {
  bool _connecte = false;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((c) {
      if (mounted) setState(() => _connecte = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _connecte ? 2 : 1,
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppBar(
          title: Text(tr('Avis clients')),
          bottom: _connecte ? TabBar(tabs: [Tab(text: tr('Tous les avis')), Tab(text: tr('Mes avis'))]) : null,
        ),
        body: _connecte ? const TabBarView(children: [_AvisPublics(), _MesAvis()]) : const _AvisPublics(),
      ),
    );
  }
}

class _AvisPublics extends StatefulWidget {
  const _AvisPublics();

  @override
  State<_AvisPublics> createState() => _AvisPublicsState();
}

class _AvisPublicsState extends State<_AvisPublics> {
  final _source = sl<AvisRemoteDataSource>();
  SyntheseAvis? _synthese;
  final List<Avis> _avis = [];
  int _page = 1;
  int _totalPages = 1;
  int? _filtre;
  String? _erreur;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger({bool suite = false}) async {
    if (_chargement) return;
    setState(() => _chargement = true);
    try {
      final page = suite ? _page + 1 : 1;
      final r = await _source.getAvisPublics(page: page, note: _filtre);
      if (!mounted) return;
      setState(() {
        if (!suite) _avis.clear();
        _avis.addAll(r.avis);
        _synthese = r.synthese;
        _page = page;
        _totalPages = r.totalPages;
        _erreur = null;
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur != null && _avis.isEmpty) {
      return EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!, actionLabel: tr('Réessayer'), onAction: _charger);
    }
    final s = _synthese;
    if (s == null) return const ShimmerList();
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        CarteSection(children: [
          Row(children: [
            Text(s.noteMoyenne.toStringAsFixed(1), style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Etoiles(s.noteMoyenne, taille: 20),
              Text('${s.total} avis', style: texteDiscret(13)),
            ]),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, children: [
            ChoiceChip(
              label: Text(tr('Tous')),
              selected: _filtre == null,
              onSelected: (_) {
                setState(() => _filtre = null);
                _charger();
              },
            ),
            for (var n = 5; n >= 1; n--)
              ChoiceChip(
                label: Text('$n/5 (${s.repartition[n] ?? 0})'),
                selected: _filtre == n,
                onSelected: (_) {
                  setState(() => _filtre = n);
                  _charger();
                },
              ),
          ]),
        ]),
        const SizedBox(height: 12),
        if (_avis.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(tr('Aucun avis pour le moment.'), textAlign: TextAlign.center, style: texteDiscret(13)),
          ),
        for (final a in _avis) _CarteAvis(avis: a),
        if (_page < _totalPages)
          Center(
            child: TextButton(
              onPressed: _chargement ? null : () => _charger(suite: true),
              child: Text(tr('Voir plus d\'avis')),
            ),
          ),
      ]),
    );
  }
}

class _MesAvis extends StatefulWidget {
  const _MesAvis();

  @override
  State<_MesAvis> createState() => _MesAvisState();
}

class _MesAvisState extends State<_MesAvis> {
  final _source = sl<AvisRemoteDataSource>();
  List<Avis>? _avis;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final liste = await _source.getMesAvis();
      if (mounted) setState(() => _avis = liste);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _supprimer(Avis a) async {
    try {
      final message = await _source.supprimer(a.id);
      if (mounted && message.isNotEmpty) showToast(context, tr('Supprimé'), message, ToastificationType.success);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    }
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _avis;
    if (_erreur != null) return EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!);
    if (liste == null) return const ShimmerList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await donnerAvis(context)) _charger();
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(tr('Donner mon avis')),
      ),
      body: liste.isEmpty
          ? EmptyState(
              icon: Icons.rate_review_outlined,
              title: tr('Aucun avis'),
              subtitle: tr('Partagez votre expérience : elle aide les autres clients.'),
            )
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
              for (final a in liste)
                _CarteAvis(
                  avis: a,
                  statut: kStatutsAvis[a.statut] ?? a.statut,
                  onSupprimer: () => _supprimer(a),
                ),
            ]),
    );
  }
}

class _CarteAvis extends StatelessWidget {
  final Avis avis;
  final String? statut;
  final VoidCallback? onSupprimer;
  const _CarteAvis({required this.avis, this.statut, this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    final a = avis;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Etoiles(a.note),
          const SizedBox(width: 8),
          Expanded(child: Text(formaterDate(a.date.toIso8601String()), style: texteDiscret(11))),
          if (onSupprimer != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onSupprimer,
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColor.kErreur),
            ),
        ]),
        if ((a.titre ?? '').isNotEmpty)
          Text(a.titre!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
        if ((a.commentaire ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(a.commentaire!, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          ),
        if (a.auteur != null) Text('— ${a.auteur}', style: texteDiscret(12)),
        if (a.colisReference != null) Text(tr('Expédition ${a.colisReference}'), style: texteDiscret(12)),
        if (statut != null) Text(statut!, style: texteDiscret(12)),
        if ((a.motifRejet ?? '').isNotEmpty) Text(a.motifRejet!, style: const TextStyle(color: AppColor.kErreur, fontSize: 12)),
        if ((a.reponse ?? '').isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(10)),
            child: Text(tr('Réponse de Yobante : ${a.reponse}'), style: GoogleFonts.plusJakartaSans(fontSize: 12)),
          ),
      ]),
    );
  }
}
