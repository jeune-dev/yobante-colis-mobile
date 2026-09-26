import 'package:flutter/material.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/espace_client_remote_datasource.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/i18n/langue.dart';

/// Vérification du numéro de téléphone du compte : un code à 6 chiffres est
/// envoyé par WhatsApp, puis saisi ici. Le backend exige cette preuve avant de
/// montrer les colis dont le compte est destinataire (rapprochés par numéro).
///
/// Renvoie `true` si le numéro est vérifié à la fermeture.
Future<bool> verifierTelephone(BuildContext context) async {
  final resultat = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _VerificationTelephoneDialog(),
  );
  return resultat == true;
}

class _VerificationTelephoneDialog extends StatefulWidget {
  const _VerificationTelephoneDialog();

  @override
  State<_VerificationTelephoneDialog> createState() => _VerificationTelephoneDialogState();
}

class _VerificationTelephoneDialogState extends State<_VerificationTelephoneDialog> {
  final _source = sl<EspaceClientRemoteDataSource>();
  final _code = TextEditingController();
  bool _codeEnvoye = false;
  bool _envoi = false;
  String? _info;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _executer(Future<void> Function() action) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await action();
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _demanderCode() => _executer(() async {
        final message = await _source.demanderCodeTelephone();
        if (!mounted) return;
        // Numéro déjà vérifié côté serveur : rien d'autre à faire
        if (message.contains('déjà vérifié')) {
          Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _codeEnvoye = true;
          _info = message;
        });
      });

  Future<void> _verifier() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _erreur = tr('Saisissez les 6 chiffres reçus.'));
      return;
    }
    await _executer(() async {
      await _source.verifierTelephone(code);
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Vérifier mon numéro')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _codeEnvoye
                ? (_info ?? tr('Saisissez le code reçu par WhatsApp.'))
                : tr('Pour voir les colis qui vous sont adressés, confirmez que ce numéro vous appartient. '
                    'Un code à 6 chiffres vous sera envoyé par WhatsApp.'),
            style: texteDiscret(13),
          ),
          if (_codeEnvoye) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('Code de vérification'), counterText: ''),
              onSubmitted: (_) => _verifier(),
            ),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 8),
            Text(_erreur!, style: const TextStyle(color: AppColor.kErreur, fontSize: 12)),
          ],
          if (_envoi) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _envoi ? null : () => Navigator.of(context).pop(false),
          child: Text(tr('Annuler')),
        ),
        if (_codeEnvoye)
          TextButton(onPressed: _envoi ? null : _demanderCode, child: Text(tr('Renvoyer'))),
        ElevatedButton(
          onPressed: _envoi ? null : (_codeEnvoye ? _verifier : _demanderCode),
          child: Text(_codeEnvoye ? tr('Valider') : tr('Recevoir le code')),
        ),
      ],
    );
  }
}
