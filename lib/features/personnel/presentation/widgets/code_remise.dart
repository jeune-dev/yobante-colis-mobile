import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/statuts_remise.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/personnel_remote_datasource.dart';
import 'ui_personnel.dart';

/// Issue de la feuille de remise par l'application.
enum IssueRemise {
  /// Le destinataire a confirmé dans son application.
  confirmee,

  /// Le statut a changé autrement (autre agent, incident…) : la page se recharge.
  statutChange,

  /// Le destinataire ne peut pas utiliser l'application : remise classique.
  sansApplication,
}

/// Remise à un destinataire titulaire d'un compte : affiche un code à usage
/// unique qu'il saisit dans son application, et attend sa confirmation.
/// Renvoie `null` si l'agent a simplement fermé la feuille.
Future<IssueRemise?> remiseParApplication(BuildContext context, ColisTerrain colis) {
  return showModalBottomSheet<IssueRemise>(
    context: context,
    isScrollControlled: true,
    // Fermeture volontaire uniquement (« Fermer ») : un geste ne doit pas l'interrompre
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColor.kBackground,
    builder: (_) => _FeuilleCodeRemise(colis: colis),
  );
}

class _FeuilleCodeRemise extends StatefulWidget {
  final ColisTerrain colis;
  const _FeuilleCodeRemise({required this.colis});

  @override
  State<_FeuilleCodeRemise> createState() => _FeuilleCodeRemiseState();
}

class _FeuilleCodeRemiseState extends State<_FeuilleCodeRemise> {
  final _source = sl<PersonnelRemoteDataSource>();
  String? _code;
  DateTime? _expireLe;
  String? _erreur;
  Timer? _horloge;
  Timer? _suivi;
  bool _verification = false;
  bool _generation = false;

  @override
  void initState() {
    super.initState();
    _generer();
    // La confirmation se fait sur l'appareil du destinataire : on la guette ici
    _suivi = Timer.periodic(const Duration(seconds: 3), (_) => _verifier());
    _horloge = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Code expiré : on en affiche un nouveau sans que l'agent ait à le demander
      if (_expireLe != null && DateTime.now().isAfter(_expireLe!)) _generer();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _horloge?.cancel();
    _suivi?.cancel();
    super.dispose();
  }

  Future<void> _generer() async {
    if (_generation) return;
    _generation = true;
    setState(() {
      _code = null;
      _expireLe = null;
      _erreur = null;
    });
    try {
      final r = await _source.genererCodeRemise(widget.colis.id);
      if (mounted) {
        setState(() {
          _code = r.code;
          _expireLe = r.expireLe;
        });
      }
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      _generation = false;
    }
  }

  Future<void> _verifier() async {
    if (_verification || _code == null) return;
    _verification = true;
    try {
      final c = await _source.getColisDetail(widget.colis.id);
      if (!mounted || kStatutsRemise.contains(c.statut)) return;
      Navigator.of(context).pop(kStatutsRemis.contains(c.statut) ? IssueRemise.confirmee : IssueRemise.statutChange);
    } on ServerException catch (e) {
      // Colis sorti des missions de l'agent (remis, confié à un autre…) : la
      // page se recharge et l'explique. Sinon, réseau momentané : nouvel essai.
      if (mounted && e.code == kCodeIntrouvable) Navigator.of(context).pop(IssueRemise.statutChange);
    } finally {
      _verification = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restant = _expireLe?.difference(DateTime.now());
    final code = restant == null || restant.isNegative ? null : _code;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(tr('Remise par l\'application'), style: titreSection(18)),
            const SizedBox(height: 4),
            Text(
              tr(
                'Montrez ce code à ${widget.colis.destinataireNom} : dans son application Yobante Colis, il ouvre « Colis reçus » puis touche « Confirmer la réception ».',
              ),
              style: texteDiscret(13),
            ),
            const SizedBox(height: 20),
            if (_erreur != null) ...[
              Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColor.kErreur),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _generer,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('Réessayer')),
                ),
              ),
            ] else if (code == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '${code.substring(0, 3)} ${code.substring(3)}',
                  key: const Key('code-remise'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColor.kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tr('Valable encore ${restant!.inMinutes}:${(restant.inSeconds % 60).toString().padLeft(2, '0')}'),
                textAlign: TextAlign.center,
                style: texteDiscret(13),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(tr('En attente de la confirmation du destinataire…'), style: texteDiscret(12)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: styleBoutonContour(AppColor.kPrimary),
                    child: Text(tr('Fermer')),
                  ),
                ),
                // Pas de téléphone, de réseau, ou un proche vient à sa place : remise au
                // code de retrait (sans lui, seul un administrateur peut passer outre)
                if (widget.colis.aCodeRetrait) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(IssueRemise.sansApplication),
                      style: styleBoutonContour(AppColor.kPrimary),
                      child: Text(tr('Sans l\'application'), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
