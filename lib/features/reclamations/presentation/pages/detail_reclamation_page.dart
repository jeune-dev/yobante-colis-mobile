import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/reclamations_remote_datasource.dart';
import 'reclamations_page.dart';
import '../../../../core/i18n/langue.dart';

/// Détail d'une réclamation : échanges avec le service client, réponse et,
/// une fois le dossier clos, note de satisfaction.
class DetailReclamationPage extends StatefulWidget {
  final String id;
  const DetailReclamationPage({super.key, required this.id});

  @override
  State<DetailReclamationPage> createState() => _DetailReclamationPageState();
}

class _DetailReclamationPageState extends State<DetailReclamationPage> {
  final _source = sl<ReclamationsRemoteDataSource>();
  final _reponse = TextEditingController();
  Reclamation? _reclamation;
  String? _erreur;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _reponse.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final r = await _source.getReclamation(widget.id);
      if (!mounted) return;
      setState(() {
        _reclamation = r;
        _erreur = null;
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _action(Future<void> Function() action, String succes) async {
    setState(() => _envoi = true);
    try {
      await action();
      if (!mounted) return;
      showToast(context, tr('Envoyé'), succes, ToastificationType.success);
      await _charger();
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _repondre() async {
    final texte = _reponse.text.trim();
    if (texte.isEmpty) return;
    await _action(() async {
      await _source.repondre(widget.id, texte);
      _reponse.clear();
    }, tr('Votre message a été transmis au service client.'));
  }

  @override
  Widget build(BuildContext context) {
    final r = _reclamation;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(r?.reference ?? tr('Réclamation'))),
      body: _erreur != null && r == null
          ? EmptyState(
              icon: Icons.error_outline,
              title: tr('Erreur'),
              subtitle: _erreur!,
              actionLabel: tr('Réessayer'),
              onAction: _charger,
            )
          : r == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (_envoi) const LinearProgressIndicator(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView(padding: const EdgeInsets.all(16), children: [
                        CarteSection(
                          titre: r.objet,
                          icone: Icons.support_agent_outlined,
                          action: PastilleStatutReclamation(statut: r.statut),
                          children: [
                            LigneInfo(tr('Motif'), r.typeLibelle),
                            if (r.colisReference != null) LigneInfo(tr('Expédition'), r.colisReference!),
                            LigneInfo(tr('Ouverte le'), formaterDate(r.createdAt.toIso8601String(), avecHeure: true)),
                            if (r.montantReclame > 0)
                              LigneInfo(tr('Montant demandé'), formaterMontant(r.montantReclame, r.devise)),
                            if (r.montantAccorde != null)
                              LigneInfo(tr('Montant accordé'), formaterMontant(r.montantAccorde, r.devise), fort: true),
                            const SizedBox(height: 4),
                            Text(r.description, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                          ],
                        ),
                        if (r.resolution != null || r.motifRejet != null) ...[
                          const SizedBox(height: 12),
                          Bandeau(
                            icone: r.statut == 'rejetee' ? Icons.cancel_outlined : Icons.check_circle_outline,
                            titre: r.statut == 'rejetee' ? tr('Réclamation rejetée') : tr('Résolution'),
                            message: r.resolution ?? r.motifRejet,
                            couleur: r.statut == 'rejetee' ? AppColor.kErreur : AppColor.kSucces,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(tr('Échanges'), style: titreSection()),
                        const SizedBox(height: 8),
                        if (r.messages.isEmpty)
                          Text(tr('Aucun message pour le moment. Notre service client vous répondra ici.'),
                              style: texteDiscret(13)),
                        for (final m in r.messages) _Bulle(message: m),
                        if (r.estClose) ...[
                          const SizedBox(height: 16),
                          _Notation(
                            note: r.noteSatisfaction,
                            onNoter: (n) => _action(() => _source.noter(r.id, n), tr('Merci pour votre retour.')),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  if (!r.estClose)
                    SafeArea(
                      top: false,
                      child: Container(
                        color: AppColor.kWhite,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _reponse,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 2000,
                              decoration: InputDecoration(
                                hintText: tr('Votre message…'),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _envoi ? null : _repondre,
                            icon: const Icon(Icons.send_rounded, color: AppColor.kPrimary),
                          ),
                        ]),
                      ),
                    ),
                ]),
    );
  }
}

class _Bulle extends StatelessWidget {
  final MessageReclamation message;
  const _Bulle({required this.message});

  @override
  Widget build(BuildContext context) {
    final client = message.deClient;
    return Align(
      alignment: client ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: client ? AppColor.kPrimary.withValues(alpha: 0.12) : AppColor.kWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client ? tr('Vous') : tr('Service client'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kGrayscale40)),
          const SizedBox(height: 4),
          Text(message.message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          for (final url in message.piecesJointes)
            TextButton.icon(
              onPressed: () => ouvrirLien(context, url),
              icon: const Icon(Icons.attach_file, size: 16),
              label: Text(tr('Pièce jointe')),
            ),
          const SizedBox(height: 4),
          Text(formaterDate(message.createdAt.toIso8601String(), avecHeure: true), style: texteDiscret(10)),
        ]),
      ),
    );
  }
}

class _Notation extends StatelessWidget {
  final int? note;
  final ValueChanged<int> onNoter;
  const _Notation({required this.note, required this.onNoter});

  @override
  Widget build(BuildContext context) {
    return CarteSection(titre: tr('Votre satisfaction'), icone: Icons.star_outline, children: [
      Text(note == null ? tr('Comment évaluez-vous le traitement de votre réclamation ?') : tr('Merci pour votre note.'),
          style: texteDiscret(13)),
      Row(children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: note == null ? () => onNoter(i) : null,
            icon: Icon((note ?? 0) >= i ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColor.kSecondary, size: 30),
          ),
      ]),
    ]);
  }
}
