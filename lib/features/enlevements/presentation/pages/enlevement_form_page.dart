import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../adresses/presentation/pages/adresses_page.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../colis/domain/entities/colis.dart';
import '../../../expedition/presentation/widgets/selecteur_ville.dart';
import '../../data/enlevements_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

/// Programmation (ou modification) d'un enlèvement à domicile.
/// Renvoie la demande enregistrée.
class EnlevementFormPage extends StatefulWidget {
  /// Demande à modifier ; nulle pour une nouvelle demande.
  final DemandeEnlevement? demande;

  /// Expédition à faire enlever (depuis le détail d'un colis).
  final Colis? colis;

  const EnlevementFormPage({super.key, this.demande, this.colis});

  @override
  State<EnlevementFormPage> createState() => _EnlevementFormPageState();
}

class _EnlevementFormPageState extends State<EnlevementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _source = sl<EnlevementsRemoteDataSource>();
  late final DemandeEnlevement? _d = widget.demande;
  late final _contactNom = TextEditingController(text: _d?.contactNom ?? widget.colis?.expediteurNom);
  late final _contactTel = TextEditingController(text: _d?.contactTelephone ?? widget.colis?.expediteurTelephone);
  late final _adresse = TextEditingController(text: _d?.adresse ?? widget.colis?.adresseDepart);
  late final _complement = TextEditingController(text: _d?.complementAdresse);
  late final _codePostal = TextEditingController(text: _d?.codePostal ?? widget.colis?.codePostalDepart);
  late final _poids = TextEditingController(text: _d?.poidsEstimeKg?.toString());
  late final _etage = TextEditingController(text: _d?.etage?.toString());
  late final _instructions = TextEditingController(text: _d?.instructions);

  late String _pays = _d?.pays ?? widget.colis?.paysDepart ?? 'FR';
  late int _nbColis = _d?.nbColis ?? widget.colis?.nbPieces ?? 1;
  late bool? _ascenseur = _d?.ascenseur;
  late bool _emballage = _d?.emballageRequis ?? false;
  late String? _date = _d?.dateSouhaitee;
  late String _creneau = _d?.creneau ?? kCreneauxEnlevement.first;
  CreneauxEnlevement _creneaux = const CreneauxEnlevement();
  List<VilleDesservie> _villes = const [];
  VilleDesservie? _ville;
  bool _envoi = false;

  bool get _edition => _d != null;

  @override
  void initState() {
    super.initState();
    _source.getCreneaux().then((c) {
      if (!mounted) return;
      setState(() {
        _creneaux = c;
        _date ??= c.dates.firstOrNull;
      });
    }, onError: (_) {});
    if (!_edition) _chargerVilles(villeId: widget.colis?.villeDepartId);
  }

  @override
  void dispose() {
    for (final c in [_contactNom, _contactTel, _adresse, _complement, _codePostal, _poids, _etage, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerVilles({String? villeId}) async {
    try {
      final villes = await sl<CatalogueRemoteDataSource>().getVilles(pays: _pays);
      if (!mounted) return;
      setState(() {
        _villes = villes.where((v) => v.enlevementDomicile).toList();
        _ville = _villes.where((v) => v.id == villeId).firstOrNull;
      });
    } on ServerException catch (_) {}
  }

  /// Pré-remplissage depuis une adresse d'expéditeur du carnet.
  Future<void> _depuisCarnet() async {
    final a = await AdressesPage.choisir(context, usage: 'expediteur');
    if (a == null || !mounted) return;
    setState(() {
      _contactNom.text = a.nom;
      _contactTel.text = a.telephone;
      _adresse.text = a.adresse;
      _complement.text = a.complementAdresse ?? '';
      _codePostal.text = a.codePostal ?? '';
      _pays = a.pays;
    });
    await _chargerVilles(villeId: a.villeId);
  }

  Future<void> _choisirDate() async {
    final demain = DateTime.now().add(const Duration(days: 1));
    final choix = await showDatePicker(
      context: context,
      firstDate: DateTime(demain.year, demain.month, demain.day),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.tryParse(_date ?? '') ?? demain,
    );
    if (choix != null) setState(() => _date = choix.toIso8601String().substring(0, 10));
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      showToast(context, tr('Date requise'), tr('Choisissez la date de l\'enlèvement.'), ToastificationType.warning);
      return;
    }
    if (!_edition && _ville == null) {
      showToast(context, tr('Ville requise'), tr('Choisissez la ville de l\'enlèvement.'), ToastificationType.warning);
      return;
    }
    final commun = <String, dynamic>{
      'contactNom': _contactNom.text.trim(),
      'contactTelephone': normaliserTelephone(_contactTel.text, paysParDefaut: _pays),
      'adresse': _adresse.text.trim(),
      'complementAdresse': _texte(_complement),
      'dateSouhaitee': _date,
      'creneau': _creneau,
      'nbColis': _nbColis,
      'instructions': _texte(_instructions),
      'etage': int.tryParse(_etage.text.trim()),
      'ascenseur': _ascenseur,
      'emballageRequis': _emballage,
    };
    setState(() => _envoi = true);
    try {
      if (_edition) {
        final maj = await _source.modifier(_d!.id, commun);
        if (!mounted) return;
        if (maj.message.isNotEmpty) showToast(context, tr('Enregistré'), maj.message, ToastificationType.success);
        Navigator.of(context).pop(maj.demande);
      } else {
        final r = await _source.creer({
          ...commun,
          'colisId': ?widget.colis?.id,
          'pays': _pays,
          'villeId': _ville!.id,
          'codePostal': _texte(_codePostal),
          'poidsEstimeKg': double.tryParse(_poids.text.trim().replaceAll(',', '.')),
        });
        if (!mounted) return;
        showToast(context, tr('Enlèvement programmé'), r.message, ToastificationType.success);
        Navigator.of(context).pop(r.demande);
      }
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = {..._creneaux.dates, ?_date}.toList()..sort();
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(_edition ? tr('Modifier l\'enlèvement') : tr('Programmer un enlèvement'))),
      body: AbsorbPointer(
        absorbing: _envoi,
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_envoi) const LinearProgressIndicator(),
            if (widget.colis != null) ...[
              Bandeau(icone: Icons.inventory_2_outlined, titre: tr('Expédition ${widget.colis!.reference}')),
              const SizedBox(height: 16),
            ],
            CarteSection(
              titre: tr('Où récupérer le colis'),
              icone: Icons.home_work_outlined,
              action: _edition
                  ? null
                  : TextButton.icon(
                      onPressed: _depuisCarnet,
                      icon: const Icon(Icons.contacts_outlined, size: 18),
                      label: Text(tr('Carnet')),
                    ),
              children: [
                ChampTexte(
                  controller: _contactNom,
                  label: tr('Personne à contacter'),
                  maxLength: 120,
                  validator: texte(requis: true, min: 2, max: 120, message: tr('Nom requis')),
                ),
                ChampTexte(
                  controller: _contactTel,
                  label: tr('Téléphone'),
                  clavier: TextInputType.phone,
                  validator: validerTelephone,
                ),
                if (!_edition) ...[
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'FR', label: Text(tr('France'))),
                      ButtonSegment(value: 'SN', label: Text(tr('Sénégal'))),
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
                    onChanged: (v) => setState(() => _ville = v),
                  ),
                  const SizedBox(height: 12),
                ] else
                  LigneInfo(tr('Ville'), _d!.villeNom ?? '—'),
                ChampTexte(
                  controller: _adresse,
                  label: tr('Adresse'),
                  maxLength: 255,
                  validator: texte(requis: true, min: 3, max: 255, message: tr('Adresse requise')),
                ),
                ChampTexte(controller: _complement, label: tr('Complément (bâtiment, code…)'), maxLength: 255),
                if (!_edition)
                  ChampTexte(
                    controller: _codePostal,
                    label: tr('Code postal'),
                    clavier: TextInputType.number,
                    maxLength: 10,
                    validator: codePostal(pays: _pays),
                  ),
                Row(children: [
                  Expanded(
                    child: ChampTexte(
                      controller: _etage,
                      label: tr('Étage'),
                      clavier: const TextInputType.numberWithOptions(signed: true),
                      maxLength: 3,
                      validator: entier(min: -5, max: 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      initialValue: _ascenseur,
                      decoration: InputDecoration(labelText: tr('Ascenseur')),
                      items: [
                        DropdownMenuItem(value: null, child: Text('—')),
                        DropdownMenuItem(value: true, child: Text(tr('Oui'))),
                        DropdownMenuItem(value: false, child: Text(tr('Non'))),
                      ],
                      onChanged: (v) => setState(() => _ascenseur = v),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Quand'), icone: Icons.event_outlined, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final d in dates)
                  ChoiceChip(
                    label: Text(formaterDate(d)),
                    selected: _date == d,
                    onSelected: (_) => setState(() => _date = d),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month, size: 18),
                  label: Text(tr('Autre date')),
                  onPressed: _choisirDate,
                ),
              ]),
              const SizedBox(height: 12),
              Text(tr('Créneau'), style: texteDiscret(13)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final c in _creneaux.creneaux)
                  ChoiceChip(
                    label: Text(c.replaceAll('-', ' – ')),
                    selected: _creneau == c,
                    onSelected: (_) => setState(() => _creneau = c),
                  ),
              ]),
            ]),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Colis'), icone: Icons.inventory_2_outlined, children: [
              Row(children: [
                Expanded(child: Text(tr('Nombre de colis'), style: texteDiscret(13))),
                CompteurQuantite(valeur: _nbColis, max: 100, onChanged: (v) => setState(() => _nbColis = v < 1 ? 1 : v)),
              ]),
              if (!_edition)
                ChampTexte(
                  controller: _poids,
                  label: tr('Poids estimé total (kg, facultatif)'),
                  clavier: const TextInputType.numberWithOptions(decimal: true),
                  validator: nombre(max: 1000, strictementPositif: true),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Emballage à prévoir par le coursier')),
                value: _emballage,
                onChanged: (v) => setState(() => _emballage = v),
              ),
              ChampTexte(controller: _instructions, label: tr('Instructions pour le coursier'), maxLines: 2, maxLength: 500),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enregistrer,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(_edition ? tr('Enregistrer') : tr('Programmer l\'enlèvement')),
            ),
          ]),
        ),
      ),
    );
  }
}
