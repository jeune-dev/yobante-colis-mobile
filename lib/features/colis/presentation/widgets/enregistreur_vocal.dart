import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/colis_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';

/// Enregistre un message vocal décrivant le colis et l'envoie au backend
/// (`POST /client/colis/:id/vocal`, remplace le précédent). Renvoie `true` si envoyé.
Future<bool> enregistrerMessageVocal(BuildContext context, String colisId) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _EnregistreurVocal(colisId: colisId),
  );
  return ok == true;
}

class _EnregistreurVocal extends StatefulWidget {
  final String colisId;
  const _EnregistreurVocal({required this.colisId});

  @override
  State<_EnregistreurVocal> createState() => _EnregistreurVocalState();
}

class _EnregistreurVocalState extends State<_EnregistreurVocal> {
  static const _dureeMax = Duration(minutes: 2);

  final _enregistreur = AudioRecorder();
  Timer? _minuteur;
  Duration _duree = Duration.zero;
  bool _enCours = false;
  String? _fichier;
  bool _envoi = false;

  @override
  void dispose() {
    _minuteur?.cancel();
    _enregistreur.dispose();
    super.dispose();
  }

  Future<void> _demarrer() async {
    if (!await _enregistreur.hasPermission()) {
      if (mounted) {
        showToast(context, tr('Micro indisponible'), tr('Autorisez l\'accès au micro dans les réglages du téléphone.'),
            ToastificationType.warning);
      }
      return;
    }
    final dossier = await getTemporaryDirectory();
    final chemin = '${dossier.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _enregistreur.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: chemin);
    setState(() {
      _enCours = true;
      _fichier = null;
      _duree = Duration.zero;
    });
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duree += const Duration(seconds: 1));
      if (_duree >= _dureeMax) _arreter();
    });
  }

  Future<void> _arreter() async {
    _minuteur?.cancel();
    final chemin = await _enregistreur.stop();
    if (mounted) {
      setState(() {
        _enCours = false;
        _fichier = chemin;
      });
    }
  }

  Future<void> _envoyer() async {
    final fichier = _fichier;
    if (fichier == null) return;
    setState(() => _envoi = true);
    try {
      final message = await sl<ColisRemoteDataSource>().deposerVocal(widget.colisId, fichier);
      if (!mounted) return;
      showToast(context, tr('Message envoyé'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  String get _chrono =>
      '${_duree.inMinutes.toString().padLeft(2, '0')}:${(_duree.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(tr('Message vocal'), style: titreSection(18)),
        const SizedBox(height: 6),
        Text(tr('Décrivez votre colis de vive voix (2 minutes maximum).'), style: texteDiscret(13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text(_chrono, style: titreSection(32)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _envoi ? null : (_enCours ? _arreter : _demarrer),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: _enCours ? AppColor.kErreur : AppColor.kPrimary,
            child: Icon(_enCours ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _enCours ? tr('Enregistrement… touchez pour arrêter') : _fichier == null ? tr('Touchez pour enregistrer') : tr('Enregistrement prêt'),
          style: texteDiscret(12),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _envoi
                  ? null
                  : () async {
                      if (_enCours) await _enregistreur.cancel();
                      if (context.mounted) Navigator.of(context).pop(false);
                    },
              child: Text(tr('Annuler')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _fichier == null || _envoi || _enCours ? null : _envoyer,
              child: _envoi
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr('Envoyer')),
            ),
          ),
        ]),
      ]),
    );
  }
}
