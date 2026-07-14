import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/primary_text_form_field.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../injection_container.dart';
import '../../../villes/domain/entities/ville.dart';
import '../../../villes/presentation/bloc/villes_bloc.dart';
import '../../../villes/presentation/bloc/villes_event.dart';
import '../../../villes/presentation/bloc/villes_state.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import 'package:toastification/toastification.dart';

class CreationColisPage extends StatefulWidget {
  const CreationColisPage({super.key});

  @override
  State<CreationColisPage> createState() => _CreationColisPageState();
}

class _CreationColisPageState extends State<CreationColisPage> {
  final _formKey = GlobalKey<FormState>();
  final _expNom = TextEditingController();
  final _expTel = TextEditingController();
  final _destNom = TextEditingController();
  final _destTel = TextEditingController();
  final _adresse = TextEditingController();
  final _poids = TextEditingController();
  final _description = TextEditingController();
  final _valeurDeclaree = TextEditingController();

  String _typeColis = 'standard';
  Ville? _villeDepart;
  Ville? _villeArrivee;

  @override
  void dispose() {
    _expNom.dispose(); _expTel.dispose(); _destNom.dispose();
    _destTel.dispose(); _adresse.dispose(); _poids.dispose();
    _description.dispose(); _valeurDeclaree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VillesBloc(getVilles: sl())..add(const LoadVilles()),
      child: BlocConsumer<ColisBloc, ColisState>(
        listener: (ctx, state) {
          if (state is ColisCreated) {
            showToast(ctx, 'Succès', 'Colis créé ! Réf : ${state.colis.reference}', ToastificationType.success);
            Navigator.of(ctx).pop();
          }
          if (state is ColisFailure) {
            showToast(ctx, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (ctx, state) {
          final isLoading = state is ColisLoading || state is ColisUploadProgress;
          return Scaffold(
            backgroundColor: AppColor.kBackground,
            appBar: AppBar(title: const Text('Nouveau colis')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Expéditeur'),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _expNom,
                      hintText: 'Nom de l\'expéditeur',
                      validator: (v) => v == null || v.trim().length < 2 ? 'Requis (min 2 car.)' : null,
                    ),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _expTel,
                      hintText: 'Téléphone expéditeur',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<VillesBloc, VillesState>(builder: (_, vs) {
                      final villes = vs is VillesLoaded ? vs.villes : <Ville>[];
                      return _VilleDropdown(
                        label: 'Ville de départ',
                        villes: villes,
                        value: _villeDepart,
                        onChanged: (v) => setState(() => _villeDepart = v),
                      );
                    }),
                    const SizedBox(height: 24),
                    _sectionTitle('Destinataire'),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _destNom,
                      hintText: 'Nom du destinataire',
                      validator: (v) => v == null || v.trim().length < 2 ? 'Requis (min 2 car.)' : null,
                    ),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _destTel,
                      hintText: 'Téléphone destinataire',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<VillesBloc, VillesState>(builder: (_, vs) {
                      final villes = vs is VillesLoaded ? vs.villes : <Ville>[];
                      return _VilleDropdown(
                        label: 'Ville d\'arrivée',
                        villes: villes,
                        value: _villeArrivee,
                        onChanged: (v) => setState(() => _villeArrivee = v),
                      );
                    }),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _adresse,
                      hintText: 'Adresse de livraison',
                      validator: (v) => v == null || v.trim().length < 5 ? 'Requis (min 5 car.)' : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Détails du colis'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _typeColis,
                      decoration: InputDecoration(
                        labelText: 'Type de colis',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'express', child: Text('Express')),
                        DropdownMenuItem(value: 'fragile', child: Text('Fragile')),
                      ],
                      onChanged: (v) => setState(() => _typeColis = v ?? 'standard'),
                    ),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _poids,
                      hintText: 'Poids (kg)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Poids invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _description,
                      hintText: 'Description (optionnel)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    PrimaryTextFormField(
                      controller: _valeurDeclaree,
                      hintText: 'Valeur déclarée FCFA (optionnel)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 32),
                    if (state is ColisUploadProgress)
                      LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'Envoyer le colis',
                      onTap: isLoading ? null : _submit,
                      isLoading: isLoading,
                      bgColor: AppColor.kPrimary,
                      textColor: AppColor.kWhite,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.kPrimary));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_villeDepart == null) {
      showToast(context, 'Erreur', 'Sélectionnez la ville de départ.', ToastificationType.error);
      return;
    }
    if (_villeArrivee == null) {
      showToast(context, 'Erreur', 'Sélectionnez la ville d\'arrivée.', ToastificationType.error);
      return;
    }
    context.read<ColisBloc>().add(CreerColisRequested(
      expediteurNom: _expNom.text.trim(),
      expediteurTelephone: _expTel.text.trim(),
      villeDepartId: _villeDepart!.id,
      destinataireNom: _destNom.text.trim(),
      destinataireTelephone: _destTel.text.trim(),
      villeArriveeId: _villeArrivee!.id,
      adresseLivraison: _adresse.text.trim(),
      poids: double.parse(_poids.text.trim()),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      typeColis: _typeColis,
      valeurDeclaree: _valeurDeclaree.text.trim().isEmpty ? null : double.tryParse(_valeurDeclaree.text.trim()),
    ));
  }
}

class _VilleDropdown extends StatelessWidget {
  final String label;
  final List<Ville> villes;
  final Ville? value;
  final ValueChanged<Ville?> onChanged;
  const _VilleDropdown({required this.label, required this.villes, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Ville>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: villes.map((v) => DropdownMenuItem(value: v, child: Text(v.nom))).toList(),
      onChanged: onChanged,
      validator: (_) => value == null ? 'Requis' : null,
    );
  }
}
