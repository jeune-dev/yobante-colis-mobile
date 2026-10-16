import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../avis/presentation/pages/avis_page.dart';
import '../../data/datasources/colis_remote_datasource.dart';
import '../../domain/entities/colis.dart';

/// Le destinataire saisit le code à six chiffres affiché par l'agent ou le
/// coursier : la remise est enregistrée, puis son avis lui est proposé.
/// Renvoie `true` si la réception a été confirmée.
Future<bool> confirmerRemise(BuildContext context, Colis colis) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SaisieCodeRemise(colis: colis),
  );
  if (ok != true || !context.mounted) return false;
  await donnerAvis(context, colisId: colis.id, colisReference: colis.reference);
  return true;
}

class _SaisieCodeRemise extends StatefulWidget {
  final Colis colis;
  const _SaisieCodeRemise({required this.colis});

  @override
  State<_SaisieCodeRemise> createState() => _SaisieCodeRemiseState();
}

class _SaisieCodeRemiseState extends State<_SaisieCodeRemise> {
  final _code = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_envoi) return;
    if (_code.text.length != 6) {
      setState(() => _erreur = tr('Le code compte six chiffres.'));
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final message = await sl<ColisRemoteDataSource>().confirmerRemise(widget.colis.id, _code.text);
      if (!mounted) return;
      showToast(context, tr('Colis reçu'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      // Code refusé : champ vidé pour une nouvelle saisie
      _code.clear();
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('Confirmer la réception'), style: titreSection(18)),
          Text(tr('Expédition ${widget.colis.reference}'), style: texteDiscret(13)),
          Text(tr('Envoyé par ${widget.colis.expediteurNom}'), style: texteDiscret(13)),
          const SizedBox(height: 8),
          Text(
            tr('Vérifiez votre colis, puis saisissez le code à six chiffres que l\'agent ou le livreur vous montre.'),
            style: texteDiscret(13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: InputDecoration(counterText: '', hintText: '000000', errorText: _erreur, errorMaxLines: 3),
            // Validation dès le sixième chiffre : pas de bouton à chercher
            onChanged: (v) {
              if (_erreur != null) setState(() => _erreur = null);
              if (v.length == 6) _valider();
            },
            onSubmitted: (_) => _valider(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _envoi ? null : _valider,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _envoi
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                : Text(tr('J\'ai reçu mon colis')),
          ),
        ],
      ),
    );
  }
}
