import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../colis/data/datasources/colis_remote_datasource.dart';
import '../../../colis/domain/entities/colis.dart';
import '../../data/reclamations_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

/// Ouverture d'une réclamation, éventuellement rattachée à une expédition.
/// Renvoie la réclamation créée.
class NouvelleReclamationPage extends StatefulWidget {
  /// Expédition concernée, quand la page est ouverte depuis le détail d'un colis.
  final Colis? colis;
  const NouvelleReclamationPage({super.key, this.colis});

  @override
  State<NouvelleReclamationPage> createState() => _NouvelleReclamationPageState();
}

class _NouvelleReclamationPageState extends State<NouvelleReclamationPage> {
  static const _maxPieces = 5;

  final _formKey = GlobalKey<FormState>();
  final _objet = TextEditingController();
  final _description = TextEditingController();
  final _montant = TextEditingController();
  String _type = 'avarie';
  String _priorite = 'normale';
  Colis? _colis;
  List<Colis> _mesColis = const [];
  final List<String> _pieces = [];
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _colis = widget.colis;
    if (_colis == null) _chargerColis();
  }

  @override
  void dispose() {
    _objet.dispose();
    _description.dispose();
    _montant.dispose();
    super.dispose();
  }

  Future<void> _chargerColis() async {
    try {
      final res = await sl<ColisRemoteDataSource>().getColis(limit: 50);
      if (mounted) setState(() => _mesColis = (res['colis'] as List).cast<Colis>());
    } on ServerException catch (_) {
      // La liste est facultative : une réclamation peut ne viser aucun envoi
    }
  }

  Future<void> _ajouterPiece() async {
    final fichier = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1800);
    if (fichier != null && mounted) setState(() => _pieces.add(fichier.path));
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final montant = double.tryParse(_montant.text.trim().replaceAll(',', '.'));
      final r = await sl<ReclamationsRemoteDataSource>().ouvrir(
        type: _type,
        objet: _objet.text,
        description: _description.text,
        colisId: _colis?.id,
        montantReclame: montant,
        devise: montant != null && montant > 0 ? (_colis?.devise ?? 'EUR') : null,
        priorite: _priorite,
        piecesPaths: _pieces,
      );
      if (!mounted) return;
      if (r.message.isNotEmpty) {
        showToast(context, tr('Réclamation enregistrée'), r.message, ToastificationType.success);
      }
      Navigator.of(context).pop(r.reclamation);
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indemnisable = _type == 'perte' || _type == 'avarie';
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Nouvelle réclamation'))),
      body: AbsorbPointer(
        absorbing: _envoi,
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_envoi) const LinearProgressIndicator(),
            CarteSection(titre: tr('Motif'), icone: Icons.report_problem_outlined, children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: tr('Type de réclamation')),
                items: kTypesReclamation.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priorite,
                decoration: InputDecoration(labelText: tr('Urgence')),
                items: kPrioritesReclamation.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _priorite = v ?? _priorite),
              ),
              const SizedBox(height: 12),
              if (widget.colis != null)
                LigneInfo(tr('Expédition'), widget.colis!.reference, fort: true)
              else
                DropdownButtonFormField<String?>(
                  initialValue: _colis?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('Expédition concernée (facultatif)')),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(tr('Aucune expédition'))),
                    ..._mesColis.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text('${c.reference} · ${c.destinataireNom}', overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (id) => setState(() => _colis = _mesColis.where((c) => c.id == id).firstOrNull),
                ),
            ]),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Votre demande'), icone: Icons.edit_note, children: [
              ChampTexte(
                controller: _objet,
                label: tr('Objet'),
                maxLength: 150,
                validator: texte(requis: true, min: 3, max: 150),
              ),
              ChampTexte(
                controller: _description,
                label: tr('Décrivez le problème'),
                maxLines: 5,
                maxLength: 2000,
                validator: texte(requis: true, min: 10, max: 2000),
              ),
              if (indemnisable)
                ChampTexte(
                  controller: _montant,
                  label: tr('Indemnisation demandée (${_colis?.devise ?? 'EUR'}, facultatif)'),
                  clavier: const TextInputType.numberWithOptions(decimal: true),
                  validator: nombre(),
                ),
            ]),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Photos / justificatifs'), icone: Icons.photo_library_outlined, children: [
              Text(tr('Jusqu\'à $_maxPieces images (colis abîmé, emballage, facture…).'), style: texteDiscret()),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < _pieces.length; i++)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_pieces[i]), width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => setState(() => _pieces.removeAt(i)),
                        child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ]),
                if (_pieces.length < _maxPieces)
                  InkWell(
                    onTap: _ajouterPiece,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.kLine),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColor.kGrayscale40),
                    ),
                  ),
              ]),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _envoyer,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(tr('Envoyer la réclamation')),
            ),
          ]),
        ),
      ),
    );
  }
}
