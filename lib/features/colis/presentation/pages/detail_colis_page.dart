import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/widgets/toast_notif.dart';

class DetailColisPage extends StatefulWidget {
  final String colisId;
  const DetailColisPage({super.key, required this.colisId});

  @override
  State<DetailColisPage> createState() => _DetailColisPageState();
}

class _DetailColisPageState extends State<DetailColisPage> {
  @override
  void initState() {
    super.initState();
    context.read<ColisBloc>().add(LoadColisDetail(widget.colisId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ColisBloc, ColisState>(
      listener: (ctx, state) {
        if (state is ColisAnnule) {
          showToast(ctx, 'Succès', 'Colis annulé avec succès.', ToastificationType.success);
          Navigator.of(ctx).pop();
        }
        if (state is ColisFailure) {
          showToast(ctx, 'Erreur', state.message, ToastificationType.error);
        }
      },
      builder: (context, state) {
        if (state is ColisLoading) {
          return Scaffold(appBar: AppBar(title: const Text('Détail colis')), body: const ShimmerList());
        }
        if (state is ColisDetailLoaded) {
          final c = state.colis;
          final fmt = DateFormat('dd MMM yyyy', 'fr_FR');
          return Scaffold(
            backgroundColor: AppColor.kBackground,
            appBar: AppBar(
              title: Text(c.reference),
              actions: [
                if (c.statut == 'en_attente')
                  TextButton(
                    onPressed: () => _confirmerAnnulation(c.id),
                    child: const Text('Annuler', style: TextStyle(color: Colors.red)),
                  ),
                IconButton(
                  icon: const Icon(Icons.track_changes_outlined),
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.suiviColisRoute, arguments: c.id),
                  tooltip: 'Suivi',
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: StatutBadge(statut: c.statut)),
                  const SizedBox(height: 24),
                  _Section(title: 'Expéditeur', children: [
                    _Row('Nom', c.expediteurNom),
                    _Row('Téléphone', c.expediteurTelephone),
                    _Row('Ville de départ', c.villeDepartNom ?? c.villeDepartId),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'Destinataire', children: [
                    _Row('Nom', c.destinataireNom),
                    _Row('Téléphone', c.destinataireTelephone),
                    _Row('Ville d\'arrivée', c.villeArriveeNom ?? c.villeArriveeId),
                    _Row('Adresse', c.adresseLivraison),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'Détails du colis', children: [
                    _Row('Type', c.typeColis),
                    _Row('Poids', '${c.poids} kg'),
                    if (c.description != null) _Row('Description', c.description!),
                    if (c.valeurDeclaree != null) _Row('Valeur déclarée', '${c.valeurDeclaree!.toStringAsFixed(0)} FCFA'),
                    if (c.montant != null) _Row('Montant transport', '${c.montant!.toStringAsFixed(0)} FCFA'),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'Dates', children: [
                    _Row('Créé le', fmt.format(c.createdAt)),
                    if (c.dateLivraisonEstimee != null) _Row('Livraison estimée', c.dateLivraisonEstimee!),
                    if (c.dateLivraisonEffective != null) _Row('Livraison effective', c.dateLivraisonEffective!),
                    if (c.annuleMotif != null) _Row('Motif annulation', c.annuleMotif!),
                  ]),
                  if (c.photos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Photos', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(c.photos[i], width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Détail colis')),
          body: const Center(child: Text('Colis introuvable')),
        );
      },
    );
  }

  void _confirmerAnnulation(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le colis ?'),
        content: const Text('Cette action est irréversible. Souhaitez-vous continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ColisBloc>().add(AnnulerColisRequested(id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Annuler le colis'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColor.kPrimary)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40)),
          ),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
