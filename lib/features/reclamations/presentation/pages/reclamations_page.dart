import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../data/reclamations_remote_datasource.dart';
import 'detail_reclamation_page.dart';
import 'nouvelle_reclamation_page.dart';
import '../../../../core/i18n/langue.dart';

/// Liste des réclamations du client (service après-vente).
class ReclamationsPage extends StatefulWidget {
  const ReclamationsPage({super.key});

  @override
  State<ReclamationsPage> createState() => _ReclamationsPageState();
}

class _ReclamationsPageState extends State<ReclamationsPage> {
  final _source = sl<ReclamationsRemoteDataSource>();
  List<Reclamation>? _reclamations;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final liste = await _source.getReclamations();
      if (mounted) setState(() => _reclamations = liste);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _nouvelle() async {
    final creee = await Navigator.of(context).push<Reclamation>(
      MaterialPageRoute(builder: (_) => const NouvelleReclamationPage()),
    );
    if (creee != null) _charger();
  }

  Future<void> _ouvrir(Reclamation r) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailReclamationPage(id: r.id)));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _reclamations;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Mes réclamations'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nouvelle,
        icon: const Icon(Icons.add),
        label: Text(tr('Nouvelle réclamation')),
      ),
      body: _erreur != null
          ? EmptyState(
              icon: Icons.error_outline,
              title: tr('Erreur'),
              subtitle: _erreur!,
              actionLabel: tr('Réessayer'),
              onAction: _charger,
            )
          : liste == null
              ? const ShimmerList()
              : liste.isEmpty
                  ? EmptyState(
                      icon: Icons.support_agent_outlined,
                      title: tr('Aucune réclamation'),
                      subtitle: tr('Un souci avec un envoi (perte, avarie, retard, facture) ? '
                          'Ouvrez une réclamation, notre service client vous répond ici.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: liste.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _CarteReclamation(reclamation: liste[i], onTap: () => _ouvrir(liste[i])),
                      ),
                    ),
    );
  }
}

class _CarteReclamation extends StatelessWidget {
  final Reclamation reclamation;
  final VoidCallback onTap;
  const _CarteReclamation({required this.reclamation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = reclamation;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r.reference, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            PastilleStatutReclamation(statut: r.statut),
          ]),
          const SizedBox(height: 8),
          Text(r.objet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '${r.typeLibelle}${r.colisReference != null ? ' · ${r.colisReference}' : ''} · ${formaterDate(r.createdAt.toIso8601String())}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40),
          ),
        ]),
      ),
    );
  }
}

/// Pastille colorée du statut d'une réclamation.
class PastilleStatutReclamation extends StatelessWidget {
  final String statut;
  const PastilleStatutReclamation({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final couleur = switch (statut) {
      'resolue' || 'cloturee' => AppColor.kSucces,
      'rejetee' => AppColor.kErreur,
      'attente_client' => AppColor.kAlerte,
      _ => AppColor.kPrimary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(kStatutsReclamation[statut] ?? statut,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
    );
  }
}
