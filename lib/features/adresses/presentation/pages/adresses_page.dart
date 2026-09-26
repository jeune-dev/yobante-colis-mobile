import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/adresses_remote_datasource.dart';
import 'adresse_form_page.dart';
import '../../../../core/i18n/langue.dart';

/// Carnet d'adresses. En mode sélection ([selection] vrai), un appui renvoie
/// l'adresse choisie (pré-remplissage d'une expédition).
class AdressesPage extends StatefulWidget {
  final bool selection;

  /// Filtre des adresses proposées en sélection : `destinataire` ou `expediteur`.
  final String? usage;

  const AdressesPage({super.key, this.selection = false, this.usage});

  /// Ouvre le carnet et renvoie l'adresse choisie.
  static Future<AdresseCarnet?> choisir(BuildContext context, {String? usage}) =>
      Navigator.of(context).push<AdresseCarnet>(
        MaterialPageRoute(builder: (_) => AdressesPage(selection: true, usage: usage)),
      );

  @override
  State<AdressesPage> createState() => _AdressesPageState();
}

class _AdressesPageState extends State<AdressesPage> {
  final _source = sl<AdressesRemoteDataSource>();
  List<AdresseCarnet>? _adresses;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      var liste = await _source.getAdresses();
      if (widget.usage == 'destinataire') liste = liste.where((a) => a.estDestinataire).toList();
      if (widget.usage == 'expediteur') liste = liste.where((a) => a.estExpediteur).toList();
      if (!mounted) return;
      setState(() {
        _adresses = liste;
        _erreur = null;
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _formulaire([AdresseCarnet? adresse]) async {
    // Version à jour de l'adresse avant modification (GET /client/adresses/:id)
    if (adresse != null) {
      try {
        adresse = await _source.getAdresse(adresse.id);
      } on ServerException catch (_) {}
      if (!mounted) return;
    }
    final enregistree = await Navigator.of(context).push<AdresseCarnet>(
      MaterialPageRoute(builder: (_) => AdresseFormPage(adresse: adresse)),
    );
    if (enregistree == null || !mounted) return;
    if (widget.selection) {
      Navigator.of(context).pop(enregistree);
      return;
    }
    showToast(context, tr('Enregistré'), tr('Adresse enregistrée dans votre carnet.'), ToastificationType.success);
    _charger();
  }

  Future<void> _action(Future<void> Function() action, String succes) async {
    try {
      await action();
      if (mounted) showToast(context, tr('Carnet mis à jour'), succes, ToastificationType.success);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    }
    _charger();
  }

  Future<void> _supprimer(AdresseCarnet a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Supprimer cette adresse ?')),
        content: Text(tr('« ${a.libelle} » sera retirée de votre carnet.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Annuler'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Supprimer'), style: TextStyle(color: AppColor.kErreur)),
          ),
        ],
      ),
    );
    if (ok == true) await _action(() => _source.supprimer(a.id), tr('Adresse supprimée.'));
  }

  @override
  Widget build(BuildContext context) {
    final liste = _adresses;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(widget.selection ? tr('Choisir une adresse') : tr('Mon carnet d\'adresses'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulaire(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(tr('Ajouter')),
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
                      icon: Icons.contacts_outlined,
                      title: tr('Carnet vide'),
                      subtitle: tr('Enregistrez vos destinataires habituels pour expédier plus vite.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: liste.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _CarteAdresse(
                          adresse: liste[i],
                          onTap: widget.selection
                              ? () => Navigator.of(context).pop(liste[i])
                              : () => _formulaire(liste[i]),
                          onDefaut: liste[i].parDefaut
                              ? null
                              : () => _action(() => _source.definirParDefaut(liste[i].id), tr('Adresse par défaut modifiée.')),
                          onSupprimer: widget.selection ? null : () => _supprimer(liste[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _CarteAdresse extends StatelessWidget {
  final AdresseCarnet adresse;
  final VoidCallback onTap;
  final VoidCallback? onDefaut;
  final VoidCallback? onSupprimer;
  const _CarteAdresse({required this.adresse, required this.onTap, this.onDefaut, this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    final a = adresse;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(a.pays == 'SN' ? Icons.flag_outlined : Icons.location_on_outlined, color: AppColor.kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(a.libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
                if (a.parDefaut) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded, size: 16, color: AppColor.kAlerte),
                ],
              ]),
              Text('${a.nom} · ${a.telephone}', style: texteDiscret(12)),
              Text(a.resume, style: texteDiscret(12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (onDefaut != null || onSupprimer != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'defaut') onDefaut?.call();
                if (v == 'supprimer') onSupprimer?.call();
              },
              itemBuilder: (_) => [
                if (onDefaut != null) PopupMenuItem(value: 'defaut', child: Text(tr('Définir par défaut'))),
                if (onSupprimer != null)
                  PopupMenuItem(value: 'supprimer', child: Text(tr('Supprimer'), style: TextStyle(color: AppColor.kErreur))),
              ],
            ),
        ]),
      ),
    );
  }
}
