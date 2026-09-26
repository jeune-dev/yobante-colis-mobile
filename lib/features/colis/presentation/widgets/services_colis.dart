import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/document_page.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../avis/presentation/pages/avis_page.dart';
import '../../../enlevements/presentation/pages/enlevement_form_page.dart';
import '../../data/datasources/colis_remote_datasource.dart';
import '../../domain/entities/colis.dart';
import 'enregistreur_vocal.dart';
import '../../../../core/i18n/langue.dart';

/// Documents et services d'une expédition : étiquettes, bordereau, facture
/// commerciale, photos complémentaires, message vocal, alertes de suivi,
/// enlèvement à domicile et avis après livraison.
class ServicesColis extends StatelessWidget {
  final Colis colis;
  final VoidCallback onRecharger;
  const ServicesColis({super.key, required this.colis, required this.onRecharger});

  static const _avantValidation = ['brouillon', 'en_attente_validation', 'devis_propose', 'refuse', 'annule'];
  static const _termines = ['livre', 'recupere', 'retourne', 'annule', 'refuse'];
  static const _maxPhotos = 10;

  void _document(BuildContext context, String titre, String chemin, String prefixe) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DocumentPage(titre: titre, chemin: chemin, nomFichier: '$prefixe-${colis.reference}.html'),
    ));
  }

  Future<void> _ajouterPhotos(BuildContext context) async {
    final restant = _maxPhotos - colis.photos.length;
    final images = await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1800, limit: restant);
    if (images.isEmpty || !context.mounted) return;
    try {
      final message = await sl<ColisRemoteDataSource>()
          .ajouterPhotos(colis.id, images.take(restant).map((i) => i.path).toList());
      if (context.mounted) showToast(context, tr('Photos ajoutées'), message, ToastificationType.success);
      onRecharger();
    } on ServerException catch (e) {
      if (context.mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    }
  }

  Future<void> _alertes(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AbonnementSuivi(colis: colis),
    );
    if (ok == true) onRecharger();
  }

  @override
  Widget build(BuildContext context) {
    final c = colis;
    final valide = !_avantValidation.contains(c.statut);
    final termine = _termines.contains(c.statut);
    final factureCommerciale = c.estInternational && c.categorie != 'documents' && c.typeContenu != 'document';

    final entrees = <Widget>[
      if (valide) ...[
        _Entree(Icons.qr_code_2, tr('Étiquettes à coller'),
            () => _document(context, tr('Étiquettes'), Env.clientColisEtiquettes(c.id), 'etiquettes')),
        _Entree(Icons.receipt_outlined, tr('Bordereau de dépôt'),
            () => _document(context, tr('Bordereau'), Env.clientColisBordereau(c.id), 'bordereau')),
      ],
      if (factureCommerciale)
        _Entree(Icons.description_outlined, tr('Facture commerciale (douane)'),
            () => _document(context, tr('Facture commerciale'), Env.clientColisFactureCommerciale(c.id), 'facture-commerciale')),
      if (!termine && c.photos.length < _maxPhotos)
        _Entree(Icons.add_a_photo_outlined, tr('Ajouter des photos'), () => _ajouterPhotos(context)),
      if (!termine)
        _Entree(Icons.mic_none_rounded, tr('Message vocal'), () async {
          if (await enregistrerMessageVocal(context, c.id)) onRecharger();
        }),
      if (!termine) _Entree(Icons.notifications_active_outlined, tr('Alertes de suivi (email, SMS)'), () => _alertes(context)),
      if (c.statut == 'en_attente' && c.modeDepot != 'point_collecte')
        _Entree(Icons.local_shipping_outlined, tr('Programmer un enlèvement'), () async {
          final demande = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => EnlevementFormPage(colis: c)));
          if (demande != null) onRecharger();
        }),
      if (c.statut == 'livre' || c.statut == 'recupere')
        _Entree(Icons.star_outline_rounded, tr('Donner mon avis'),
            () => donnerAvis(context, colisId: c.id, colisReference: c.reference)),
    ];
    if (entrees.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CarteSection(
        titre: tr('Documents et services'),
        icone: Icons.widgets_outlined,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        children: entrees,
      ),
    );
  }
}

class _Entree extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  const _Entree(this.icone, this.libelle, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(icone),
        title: Text(libelle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

/// Inscription d'une adresse email ou d'un numéro aux alertes de suivi.
class _AbonnementSuivi extends StatefulWidget {
  final Colis colis;
  const _AbonnementSuivi({required this.colis});

  @override
  State<_AbonnementSuivi> createState() => _AbonnementSuiviState();
}

class _AbonnementSuiviState extends State<_AbonnementSuivi> {
  late final _destination = TextEditingController(text: widget.colis.destinataireEmail ?? '');
  String _canal = 'email';
  String _profil = 'destinataire';
  bool _envoi = false;

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  void _profilChoisi(String profil) {
    final c = widget.colis;
    setState(() {
      _profil = profil;
      final valeur = switch ((profil, _canal)) {
        ('destinataire', 'email') => c.destinataireEmail,
        ('destinataire', 'sms') => c.destinataireTelephone,
        ('expediteur', 'email') => c.expediteurEmail,
        ('expediteur', 'sms') => c.expediteurTelephone,
        _ => null,
      };
      _destination.text = valeur ?? '';
    });
  }

  Future<void> _envoyer() async {
    final destination = _destination.text.trim();
    if (destination.isEmpty) {
      showToast(context, tr('Destination requise'),
          _canal == 'email' ? tr('Saisissez une adresse email.') : tr('Saisissez un numéro de téléphone.'), ToastificationType.warning);
      return;
    }
    setState(() => _envoi = true);
    try {
      final message = await sl<ColisRemoteDataSource>()
          .abonnerSuivi(widget.colis.id, canal: _canal, destination: destination, profil: _profil);
      if (!mounted) return;
      showToast(context, tr('Alertes activées'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Alertes de suivi'), style: titreSection(18)),
        Text(tr('Chaque étape de l\'expédition sera envoyée à cette adresse.'), style: texteDiscret(13)),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'email', label: Text(tr('Email')), icon: Icon(Icons.email_outlined)),
            ButtonSegment(value: 'sms', label: Text('SMS'), icon: Icon(Icons.sms_outlined)),
          ],
          selected: {_canal},
          onSelectionChanged: (s) {
            _canal = s.first;
            _profilChoisi(_profil);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _profil,
          decoration: InputDecoration(labelText: tr('Pour qui ?')),
          items: [
            DropdownMenuItem(value: 'destinataire', child: Text(tr('Le destinataire'))),
            DropdownMenuItem(value: 'expediteur', child: Text(tr('L\'expéditeur'))),
            DropdownMenuItem(value: 'tiers', child: Text(tr('Une autre personne'))),
          ],
          onChanged: (v) => _profilChoisi(v ?? _profil),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _destination,
          keyboardType: _canal == 'email' ? TextInputType.emailAddress : TextInputType.phone,
          maxLength: 150,
          decoration: InputDecoration(
            labelText: _canal == 'email' ? tr('Adresse email') : tr('Numéro de téléphone'),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _envoi ? null : _envoyer,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(tr('Activer les alertes')),
        ),
      ]),
    );
  }
}
