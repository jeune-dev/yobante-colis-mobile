import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/datasources/espace_client_remote_datasource.dart';
import '../widgets/verification_telephone_dialog.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

/// Réglages du compte : domiciliation (tournées de collecte), notifications
/// (email, push, WhatsApp) et tarif professionnel (NINEA / Kbis).
class ReglagesComptePage extends StatefulWidget {
  const ReglagesComptePage({super.key});

  @override
  State<ReglagesComptePage> createState() => _ReglagesComptePageState();
}

class _ReglagesComptePageState extends State<ReglagesComptePage> {
  final _source = sl<EspaceClientRemoteDataSource>();
  final _codePostal = TextEditingController();
  final _ninea = TextEditingController();
  ProfilClient? _profil;
  double _remisePro = 0;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _codePostal.dispose();
    _ninea.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final profil = await _source.getProfil();
      final config = await sl<CatalogueRemoteDataSource>().getConfiguration();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _remisePro = config.remiseProPourcent;
        _codePostal.text = profil.codePostal ?? '';
        _ninea.text = profil.numeroIdentificationFiscale ?? '';
      });
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    }
  }

  /// [action] renvoie le profil à jour et le message du backend, affiché tel quel.
  Future<void> _executer(Future<({ProfilClient profil, String message})> Function() action) async {
    setState(() => _envoi = true);
    try {
      final r = await action();
      if (!mounted) return;
      setState(() => _profil = r.profil);
      if (r.message.isNotEmpty) showToast(context, tr('Enregistré'), r.message, ToastificationType.success);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _preference(String cle, bool valeur) =>
      _executer(() => _source.modifierPreferences({cle: valeur}));

  Future<void> _deposerJustificatif() async {
    if (_ninea.text.trim() != (_profil?.numeroIdentificationFiscale ?? '')) {
      await _executer(() => _source.modifierProfil({'numeroIdentificationFiscale': _ninea.text.trim()}));
    }
    final fichier = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (fichier == null || !mounted) return;
    setState(() => _envoi = true);
    try {
      final message = await _source.deposerJustificatif(fichier.path);
      if (mounted) showToast(context, tr('Justificatif envoyé'), message, ToastificationType.success);
      await _charger();
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _verifierTelephone() async {
    final message = await verifierTelephone(context);
    if (message != null) {
      if (mounted && message.isNotEmpty) showToast(context, tr('Numéro vérifié'), message, ToastificationType.success);
      await _charger();
    }
  }

  /// Export des données personnelles (RGPD) : fichier JSON partagé ou enregistré.
  Future<void> _exporterDonnees() async {
    setState(() => _envoi = true);
    try {
      final export = await _source.exporterDonnees();
      final dossier = await getTemporaryDirectory();
      final fichier = File('${dossier.path}/mes-donnees-yobante.json');
      await fichier.writeAsString(const JsonEncoder.withIndent('  ').convert(export));
      await SharePlus.instance.share(ShareParams(files: [XFile(fichier.path)], title: tr('Mes données Yobante Colis')));
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } catch (_) {
      if (mounted) showToast(context, tr('Erreur'), tr("Le fichier n'a pas pu être partagé."), ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Suppression définitive (RGPD) : mot de passe redemandé par le backend.
  Future<void> _supprimerCompte() async {
    final motDePasse = TextEditingController();
    final motif = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Supprimer mon compte')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              tr('Vos données personnelles seront effacées et vous serez déconnecté. '
              'Vos expéditions et factures passées restent archivées (obligations comptables). '
              'Cette action est définitive.'),
              style: texteDiscret(13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motDePasse,
              obscureText: true,
              decoration: InputDecoration(labelText: tr('Mot de passe')),
            ),
            TextField(
              controller: motif,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(labelText: tr('Motif (facultatif)')),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Annuler'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Supprimer'), style: TextStyle(color: AppColor.kErreur)),
          ),
        ],
      ),
    );
    final password = motDePasse.text;
    final raison = motif.text;
    if (confirme != true || !mounted) return;
    if (password.isEmpty) {
      showToast(context, tr('Mot de passe requis'), tr('Saisissez votre mot de passe pour confirmer.'), ToastificationType.warning);
      return;
    }
    setState(() => _envoi = true);
    try {
      final message = await _source.supprimerCompte(password: password, motif: raison);
      if (!mounted) return;
      showToast(context, tr('Compte supprimé'), message, ToastificationType.success);
      context.read<AuthBloc>().add(const LogoutRequested());
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profil;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Réglages du compte'))),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _envoi,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                if (_envoi) const LinearProgressIndicator(),
                CarteSection(titre: tr('Domiciliation'), icone: Icons.home_outlined, children: [
                  Text(tr('Votre code postal permet de vous prévenir des tournées de collecte dans votre secteur.'),
                      style: texteDiscret()),
                  const SizedBox(height: 12),
                  ChampTexte(controller: _codePostal, label: tr('Code postal'), clavier: TextInputType.number, maxLength: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final erreur = codePostal()(_codePostal.text);
                        if (erreur != null) {
                          showToast(context, tr('Code postal'), erreur, ToastificationType.warning);
                          return;
                        }
                        _executer(() => _source.modifierProfil({'codePostal': _codePostal.text.trim()}));
                      },
                      child: Text(tr('Enregistrer')),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                CarteSection(titre: tr('Téléphone'), icone: Icons.phone_iphone, children: [
                  Text(p.telephone ?? '—', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (p.telephoneVerifie)
                    Bandeau(icone: Icons.verified, titre: tr('Numéro vérifié'), couleur: AppColor.kSucces)
                  else ...[
                    Text(tr('Vérifiez votre numéro pour retrouver les colis qui vous sont adressés.'),
                        style: texteDiscret()),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _verifierTelephone,
                        icon: const Icon(Icons.sms_outlined),
                        label: Text(tr('Vérifier mon numéro')),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                CarteSection(titre: tr('Notifications'), icone: Icons.notifications_outlined, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Notifications sur le téléphone')),
                    value: p.notificationsPush,
                    onChanged: (v) => _preference('notificationsPush', v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Messages WhatsApp')),
                    subtitle: Text(tr('Réception de votre colis, arrivée à Dakar…')),
                    value: p.notificationsWhatsapp,
                    onChanged: (v) => _preference('notificationsWhatsapp', v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Emails')),
                    value: p.notificationsEmail,
                    onChanged: (v) => _preference('notificationsEmail', v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('SMS')),
                    value: p.notificationsSms,
                    onChanged: (v) => _preference('notificationsSms', v),
                  ),
                ]),
                const SizedBox(height: 16),
                CarteSection(titre: tr('Tarif professionnel'), icone: Icons.business_center_outlined, children: [
                  Text(
                    tr('Titulaire d\'un NINEA ou d\'un Kbis ? Transmettez votre justificatif pour bénéficier de '
                    '${_remisePro.toStringAsFixed(0)} % de remise sur vos envois.'),
                    style: texteDiscret(),
                  ),
                  const SizedBox(height: 12),
                  if (p.justificatifProValide)
                    Bandeau(icone: Icons.verified, titre: tr('Tarif professionnel actif'), couleur: AppColor.kSucces)
                  else if (p.justificatifProUrl != null)
                    Bandeau(
                      icone: Icons.hourglass_top,
                      titre: tr('Justificatif en cours de vérification'),
                      couleur: AppColor.kAlerte,
                    ),
                  if (!p.justificatifProValide) ...[
                    const SizedBox(height: 12),
                    ChampTexte(controller: _ninea, label: tr('Numéro NINEA ou SIRET'), maxLength: 30),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _ninea.text.trim().isEmpty && (p.numeroIdentificationFiscale ?? '').isEmpty
                            ? () => showToast(context, tr('Numéro requis'), tr('Renseignez votre NINEA ou SIRET.'),
                                ToastificationType.warning)
                            : _deposerJustificatif,
                        icon: const Icon(Icons.upload_file),
                        label: Text(p.justificatifProUrl == null ? tr('Envoyer mon justificatif') : tr('Remplacer le justificatif')),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                if (!p.emailVerifie)
                  Text(tr('Adresse email non confirmée.'),
                      style: GoogleFonts.plusJakartaSans(color: AppColor.kErreur, fontSize: 12)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _exporterDonnees,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(tr('Exporter mes données personnelles')),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _supprimerCompte,
                  icon: const Icon(Icons.delete_forever_outlined, color: AppColor.kErreur),
                  label: Text(tr('Supprimer mon compte'), style: TextStyle(color: AppColor.kErreur)),
                ),
              ]),
            ),
    );
  }
}
