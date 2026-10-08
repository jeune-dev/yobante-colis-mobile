import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/enlevements_remote_datasource.dart';
import 'enlevement_form_page.dart';
import '../../../../core/i18n/langue.dart';

/// Demandes d'enlèvement à domicile : suivi, modification et annulation.
class EnlevementsPage extends StatefulWidget {
  const EnlevementsPage({super.key});

  @override
  State<EnlevementsPage> createState() => _EnlevementsPageState();
}

class _EnlevementsPageState extends State<EnlevementsPage> {
  final _source = sl<EnlevementsRemoteDataSource>();
  List<DemandeEnlevement>? _demandes;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final liste = await _source.getDemandes();
      if (!mounted) return;
      setState(() {
        _demandes = liste;
        _erreur = null;
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _nouvelle() async {
    final creee = await Navigator.of(context)
        .push<DemandeEnlevement>(MaterialPageRoute(builder: (_) => const EnlevementFormPage()));
    if (creee != null) _charger();
  }

  Future<void> _ouvrir(DemandeEnlevement d) async {
    final change = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DetailEnlevementPage(id: d.id)));
    if (change == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _demandes;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Mes enlèvements'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nouvelle,
        icon: const Icon(Icons.local_shipping_outlined),
        label: Text(tr('Programmer')),
      ),
      body: _erreur != null
          ? EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!, actionLabel: tr('Réessayer'), onAction: _charger)
          : liste == null
              ? const ShimmerList()
              : liste.isEmpty
                  ? EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: tr('Aucun enlèvement'),
                      subtitle: tr('Un coursier peut passer récupérer vos colis à domicile, au créneau de votre choix.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: liste.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final d = liste[i];
                          return InkWell(
                            onTap: () => _ouvrir(d),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(d.reference,
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  ),
                                  PastilleStatutEnlevement(statut: d.statut),
                                ]),
                                const SizedBox(height: 6),
                                Text('${formaterDate(d.dateSouhaitee)} · ${d.creneau.replaceAll('-', ' – ')}',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${d.adresse}${d.villeNom != null ? ', ${d.villeNom}' : ''}',
                                    style: texteDiscret(12)),
                                if (d.colisReference != null) Text(tr('Colis ${d.colisReference}'), style: texteDiscret(12)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class PastilleStatutEnlevement extends StatelessWidget {
  final String statut;
  const PastilleStatutEnlevement({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final couleur = switch (statut) {
      'effectue' => AppColor.kSucces,
      'annule' || 'echoue' => AppColor.kErreur,
      'en_cours' => AppColor.kInfo,
      'planifie' => AppColor.kInfo,
      _ => AppColor.kAlerte,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(kStatutsEnlevement[statut] ?? statut,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
    );
  }
}

/// Détail d'une demande d'enlèvement. Renvoie `true` si elle a été modifiée ou annulée.
class DetailEnlevementPage extends StatefulWidget {
  final String id;
  const DetailEnlevementPage({super.key, required this.id});

  @override
  State<DetailEnlevementPage> createState() => _DetailEnlevementPageState();
}

class _DetailEnlevementPageState extends State<DetailEnlevementPage> {
  final _source = sl<EnlevementsRemoteDataSource>();
  DemandeEnlevement? _d;
  String? _erreur;
  bool _change = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final d = await _source.getDemande(widget.id);
      if (mounted) setState(() => _d = d);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _modifier() async {
    final maj = await Navigator.of(context)
        .push<DemandeEnlevement>(MaterialPageRoute(builder: (_) => EnlevementFormPage(demande: _d)));
    if (maj != null && mounted) {
      setState(() {
        _d = maj;
        _change = true;
      });
    }
  }

  Future<void> _annuler() async {
    final motif = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Annuler l\'enlèvement ?')),
        content: TextField(controller: motif, maxLength: 255, decoration: InputDecoration(labelText: tr('Motif (facultatif)'))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Retour'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Annuler l\'enlèvement'), style: TextStyle(color: AppColor.kErreur)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final r = await _source.annuler(widget.id, motif: motif.text);
      if (!mounted) return;
      setState(() {
        _d = r.demande;
        _change = true;
      });
      if (r.message.isNotEmpty) showToast(context, tr('Annulé'), r.message, ToastificationType.success);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_change);
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppBar(title: Text(d?.reference ?? tr('Enlèvement'))),
        body: _erreur != null
            ? EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!)
            : d == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(16), children: [
                    CarteSection(
                      titre: tr('Enlèvement'),
                      icone: Icons.local_shipping_outlined,
                      action: PastilleStatutEnlevement(statut: d.statut),
                      children: [
                        LigneInfo(tr('Date souhaitée'), formaterDate(d.dateSouhaitee), fort: true),
                        LigneInfo(tr('Créneau'), d.creneau.replaceAll('-', ' – ')),
                        if (d.datePlanifiee != null) LigneInfo(tr('Planifié le'), formaterDate(d.datePlanifiee)),
                        if (d.tourneeTitre != null) LigneInfo(tr('Tournée'), d.tourneeTitre!),
                        LigneInfo(tr('Contact'), '${d.contactNom} · ${d.contactTelephone}'),
                        LigneInfo(tr('Adresse'), [d.adresse, d.complementAdresse, d.codePostal, d.villeNom]
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .join(', ')),
                        if (d.etage != null)
                          LigneInfo(tr('Étage'), '${d.etage}${d.ascenseur == true ? tr(' (ascenseur)') : ''}'),
                        LigneInfo(tr('Colis'), '${d.nbColis}${d.poidsEstimeKg != null ? ' · ${d.poidsEstimeKg} kg' : ''}'),
                        if (d.emballageRequis) LigneInfo(tr('Emballage'), tr('À prévoir par le coursier')),
                        if (d.colisReference != null) LigneInfo(tr('Expédition'), d.colisReference!),
                        if ((d.fraisEnlevement ?? 0) > 0)
                          LigneInfo(tr('Frais'), formaterMontant(d.fraisEnlevement, d.pays == 'FR' ? 'EUR' : 'XOF')),
                        if (d.instructions != null) LigneInfo(tr('Instructions'), d.instructions!),
                        if (d.motifEchec != null) LigneInfo(tr('Motif'), d.motifEchec!),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (d.modifiable)
                      OutlinedButton.icon(
                        onPressed: _modifier,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(tr('Modifier')),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    if (d.annulable) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _annuler,
                        icon: const Icon(Icons.cancel_outlined, color: AppColor.kErreur),
                        label: Text(tr('Annuler l\'enlèvement'), style: TextStyle(color: AppColor.kErreur)),
                      ),
                    ],
                  ]),
      ),
    );
  }
}
