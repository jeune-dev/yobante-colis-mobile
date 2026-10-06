import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/validateurs.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../account/data/datasources/account_remote_datasource.dart';
import '../../data/contact_remote_datasource.dart';

/// « Nous contacter » : question commerciale, partenariat, demande hors
/// expédition. Le support répond par email.
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _sujet = TextEditingController();
  final _message = TextEditingController();
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _preremplir();
  }

  /// Client connecté : ses coordonnées sont reprises.
  Future<void> _preremplir() async {
    if (!await isUserAuthenticated()) return;
    try {
      final moi = await sl<AccountRemoteDataSource>().getMe();
      if (!mounted) return;
      setState(() {
        _prenom.text = moi.prenom ?? '';
        _nom.text = moi.nom ?? '';
        _email.text = moi.email ?? '';
        _telephone.text = moi.telephone ?? '';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _telephone, _sujet, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final message = await sl<ContactRemoteDataSource>().envoyer(
        prenom: _prenom.text,
        nom: _nom.text,
        email: _email.text,
        telephone: _telephone.text,
        sujet: _sujet.text,
        message: _message.text,
      );
      if (!mounted) return;
      showToast(context, tr('Message envoyé'), message, ToastificationType.success);
      Navigator.of(context).pop();
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Nous contacter'))),
      body: AbsorbPointer(
        absorbing: _envoi,
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_envoi) const LinearProgressIndicator(),
            Text(
              tr('Une question sur nos services ? Écrivez-nous, notre équipe vous répond par email.'),
              style: texteDiscret(),
            ),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Vos coordonnées'), icone: Icons.person_outline, children: [
              Row(children: [
                Expanded(
                  child: ChampTexte(
                    controller: _prenom,
                    label: tr('Prénom'),
                    maxLength: 80,
                    validator: texte(requis: true, max: 80),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChampTexte(
                    controller: _nom,
                    label: tr('Nom'),
                    maxLength: 80,
                    validator: texte(requis: true, max: 80),
                  ),
                ),
              ]),
              ChampTexte(
                controller: _email,
                label: tr('Email'),
                clavier: TextInputType.emailAddress,
                maxLength: 150,
                validator: email(),
              ),
              ChampTexte(
                controller: _telephone,
                label: tr('Téléphone ou WhatsApp (facultatif)'),
                clavier: TextInputType.phone,
                maxLength: 30,
                validator: (v) => v == null || v.trim().isEmpty || RegExp(r'^[0-9+().\s-]{6,30}$').hasMatch(v.trim())
                    ? null
                    : tr('Numéro de téléphone invalide'),
              ),
            ]),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Votre message'), icone: Icons.mail_outline, children: [
              ChampTexte(controller: _sujet, label: tr('Sujet (facultatif)'), maxLength: 150),
              ChampTexte(
                controller: _message,
                label: tr('Message'),
                maxLines: 6,
                maxLength: 3000,
                validator: texte(requis: true, min: 5, max: 3000),
              ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _envoi ? null : _envoyer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kSecondary,
                foregroundColor: AppColor.kPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.send_outlined),
              label: Text(tr('Envoyer')),
            ),
          ]),
        ),
      ),
    );
  }
}
