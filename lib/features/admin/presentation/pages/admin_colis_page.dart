import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../injection_container.dart';
import '../../../colis/presentation/widgets/statut_badge.dart';
import 'package:toastification/toastification.dart';

class AdminColisPage extends StatefulWidget {
  const AdminColisPage({super.key});

  @override
  State<AdminColisPage> createState() => _AdminColisPageState();
}

class _AdminColisPageState extends State<AdminColisPage> {
  List<dynamic> _colis = [];
  bool _loading = true;
  String? _error;
  String? _filtreStatut;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'limit': 50};
      if (_filtreStatut != null) params['statut'] = _filtreStatut;
      final res = await sl<Dio>().get(Env.adminColis, queryParameters: params);
      setState(() { _colis = res.data['data']['colis'] as List? ?? []; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: const Text('Gestion des colis'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: _showFiltreDialog),
        ],
      ),
      body: _loading
          ? const ShimmerList()
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _colis.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _colis[i] as Map<String, dynamic>;
                      return _AdminColisCard(colis: c, onStatutChange: () => _load());
                    },
                  ),
                ),
    );
  }

  void _showFiltreDialog() {
    final statuts = [null, 'en_attente', 'en_preparation', 'en_transit', 'arrive', 'recupere', 'livre', 'annule'];
    final labels  = ['Tous', 'En attente', 'En préparation', 'En transit', 'Arrivé', 'Récupéré', 'Livré', 'Annulé'];
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(statuts.length, (i) => ListTile(
          title: Text(labels[i]),
          trailing: _filtreStatut == statuts[i] ? const Icon(Icons.check) : null,
          onTap: () {
            Navigator.pop(context);
            setState(() => _filtreStatut = statuts[i]);
            _load();
          },
        )),
      ),
    );
  }
}

class _AdminColisCard extends StatelessWidget {
  final Map<String, dynamic> colis;
  final VoidCallback onStatutChange;
  const _AdminColisCard({required this.colis, required this.onStatutChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(colis['reference'] as String? ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))),
            StatutBadge(statut: colis['statut'] as String? ?? ''),
          ]),
          const SizedBox(height: 8),
          Text('${colis['expediteurNom']} → ${colis['destinataireNom']}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
          Text('${colis['poids']} kg · ${colis['typeColis']}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Changer le statut'),
              onPressed: () => _showStatutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatutDialog(BuildContext ctx) {
    const statuts = ['en_attente', 'en_preparation', 'en_transit', 'arrive', 'recupere', 'livre', 'annule'];
    showModalBottomSheet(
      context: ctx,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('Nouveau statut', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
          ...statuts.map((s) => ListTile(
            title: StatutBadge(statut: s),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                await sl<Dio>().patch(Env.adminColisStatut(colis['id'] as String), data: {'statut': s});
                if (ctx.mounted) showToast(ctx, 'Succès', 'Statut mis à jour.', ToastificationType.success);
                onStatutChange();
              } catch (e) {
                if (ctx.mounted) showToast(ctx, 'Erreur', e.toString(), ToastificationType.error);
              }
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
