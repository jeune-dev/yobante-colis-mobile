import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../expedition/presentation/widgets/selecteur_ville.dart';
import '../../data/adresses_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';

/// Création ou modification d'une adresse du carnet. Renvoie l'adresse enregistrée.
class AdresseFormPage extends StatefulWidget {
  final AdresseCarnet? adresse;
  const AdresseFormPage({super.key, this.adresse});

  @override
  State<AdresseFormPage> createState() => _AdresseFormPageState();
}

class _AdresseFormPageState extends State<AdresseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _libelle = TextEditingController(text: widget.adresse?.libelle);
  late final _nom = TextEditingController(text: widget.adresse?.nom);
  late final _entreprise = TextEditingController(text: widget.adresse?.entreprise);
  late final _telephone = TextEditingController(text: widget.adresse?.telephone);
  late final _email = TextEditingController(text: widget.adresse?.email);
  late final _adresse = TextEditingController(text: widget.adresse?.adresse);
  late final _complement = TextEditingController(text: widget.adresse?.complementAdresse);
  late final _quartier = TextEditingController(text: widget.adresse?.quartier);
  late final _codePostal = TextEditingController(text: widget.adresse?.codePostal);
  late final _instructions = TextEditingController(text: widget.adresse?.instructions);

  late String _type = widget.adresse?.type ?? 'destinataire';
  late String _pays = widget.adresse?.pays ?? 'SN';
  late bool _parDefaut = widget.adresse?.parDefaut ?? false;
  List<VilleDesservie> _villes = const [];
  VilleDesservie? _ville;
  bool _chargementVilles = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _chargerVilles(villeId: widget.adresse?.villeId);
  }

  @override
  void dispose() {
    for (final c in [_libelle, _nom, _entreprise, _telephone, _email, _adresse, _complement, _quartier, _codePostal, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerVilles({String? villeId}) async {
    setState(() => _chargementVilles = true);
    try {
      final villes = await sl<CatalogueRemoteDataSource>().getVilles(pays: _pays);
      if (!mounted) return;
      setState(() {
        _villes = villes;
        _ville = villes.where((v) => v.id == villeId).firstOrNull;
      });
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _chargementVilles = false);
    }
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ville == null) {
      showToast(context, tr('Ville requise'), tr('Choisissez la ville.'), ToastificationType.warning);
      return;
    }
    final champs = <String, dynamic>{
      'libelle': _libelle.text.trim(),
      'type': _type,
      'nom': _nom.text.trim(),
      'entreprise': _texte(_entreprise),
      'telephone': normaliserTelephone(_telephone.text, paysParDefaut: _pays),
      'email': _texte(_email),
      'pays': _pays,
      'villeId': _ville!.id,
      'adresse': _adresse.text.trim(),
      'complementAdresse': _texte(_complement),
      'quartier': _pays == 'SN' ? _texte(_quartier) : null,
      'codePostal': _pays == 'FR' ? _texte(_codePostal) : null,
      'instructions': _texte(_instructions),
      'parDefaut': _parDefaut,
    };
    setState(() => _envoi = true);
    try {
      final source = sl<AdressesRemoteDataSource>();
      final enregistree = widget.adresse == null
          ? await source.creer(champs)
          : await source.modifier(widget.adresse!.id, champs);
      if (mounted) Navigator.of(context).pop(enregistree);
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
      appBar: AppBar(title: Text(widget.adresse == null ? tr('Nouvelle adresse') : tr('Modifier l\'adresse'))),
      body: AbsorbPointer(
        absorbing: _envoi,
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_envoi) const LinearProgressIndicator(),
            CarteSection(titre: tr('Contact'), icone: Icons.person_outline, children: [
              ChampTexte(
                controller: _libelle,
                label: tr('Nom de l\'adresse (ex : Maman à Dakar)'),
                validator: (v) => (v ?? '').trim().length < 2 ? tr('Au moins 2 caractères') : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: tr('Utilisation')),
                items: kTypesAdresse.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              ChampTexte(
                controller: _nom,
                label: tr('Nom complet'),
                validator: (v) => (v ?? '').trim().length < 2 ? tr('Nom requis') : null,
              ),
              ChampTexte(controller: _entreprise, label: tr('Entreprise (facultatif)')),
              ChampTexte(
                controller: _telephone,
                label: tr('Téléphone'),
                clavier: TextInputType.phone,
                validator: validerTelephone,
              ),
              ChampTexte(controller: _email, label: tr('Email (facultatif)'), clavier: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Adresse'), icone: Icons.home_outlined, children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'SN', label: Text(tr('Sénégal'))),
                  ButtonSegment(value: 'FR', label: Text(tr('France'))),
                ],
                selected: {_pays},
                onSelectionChanged: (s) {
                  setState(() => _pays = s.first);
                  _chargerVilles();
                },
              ),
              const SizedBox(height: 12),
              SelecteurVille(
                label: tr('Ville'),
                villes: _villes,
                valeur: _ville,
                chargement: _chargementVilles,
                onChanged: (v) => setState(() => _ville = v),
              ),
              const SizedBox(height: 12),
              ChampTexte(
                controller: _adresse,
                label: tr('Adresse'),
                validator: (v) => (v ?? '').trim().length < 3 ? tr('Adresse requise') : null,
              ),
              ChampTexte(controller: _complement, label: tr('Complément (facultatif)')),
              if (_pays == 'SN') ChampTexte(controller: _quartier, label: tr('Quartier')),
              if (_pays == 'FR')
                ChampTexte(controller: _codePostal, label: tr('Code postal'), clavier: TextInputType.number),
              ChampTexte(controller: _instructions, label: tr('Instructions (facultatif)'), maxLines: 2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Adresse par défaut')),
                value: _parDefaut,
                onChanged: (v) => setState(() => _parDefaut = v),
              ),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enregistrer,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(tr('Enregistrer')),
            ),
          ]),
        ),
      ),
    );
  }
}
