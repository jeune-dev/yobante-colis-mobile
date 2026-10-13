import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../i18n/langue.dart';
import '../theme/app_color.dart';
import '../utils/formatters.dart';

/// Pays desservis : le backend n'accepte que les numéros sénégalais et français.
final _paysTelephone = countries.where((c) => c.code == 'SN' || c.code == 'FR').toList();

/// Champ téléphone avec drapeau et indicatif (Sénégal, France).
///
/// [controller] contient toujours le numéro complet (+221…, +33…), vide si rien
/// n'est saisi : les pages lisent et pré-remplissent ce contrôleur comme un
/// champ texte ordinaire. Un numéro déjà renseigné (profil, carnet d'adresses…)
/// est décomposé en drapeau + numéro national.
///
/// [validator] reçoit le numéro complet. Le contrôle intégré du paquet
/// (asynchrone, ignoré par `Form.validate`) est désactivé.
class ChampTelephone extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Pays proposé quand le champ est vide (« SN » ou « FR »).
  final String paysInitial;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  /// Remplace la décoration par défaut (libellé flottant comme [ChampTexte]).
  final InputDecoration? decoration;
  const ChampTelephone({
    super.key,
    required this.controller,
    this.label = '',
    this.hint,
    this.paysInitial = 'SN',
    this.validator,
    this.onChanged,
    this.decoration,
  });

  @override
  State<ChampTelephone> createState() => _ChampTelephoneState();
}

class _ChampTelephoneState extends State<ChampTelephone> {
  final _national = TextEditingController();
  final _focus = FocusNode();
  late String _pays;
  // Change quand le numéro est remplacé de l'extérieur : recrée le champ du
  // paquet, dont le pays n'est lu qu'à la création.
  int _generation = 0;
  String _dernierEcrit = '';

  static const _indicatifs = {'SN': '221', 'FR': '33'};

  @override
  void initState() {
    super.initState();
    _decomposer(widget.controller.text);
    widget.controller.addListener(_surChangementExterieur);
  }

  @override
  void didUpdateWidget(ChampTelephone ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.controller != widget.controller) {
      ancien.controller.removeListener(_surChangementExterieur);
      widget.controller.addListener(_surChangementExterieur);
      setState(() {
        _decomposer(widget.controller.text);
        _generation++;
      });
    } else if (ancien.paysInitial != widget.paysInitial && _national.text.isEmpty) {
      // Champ encore vide : il suit le pays choisi ailleurs dans le formulaire
      setState(() {
        _pays = widget.paysInitial;
        _generation++;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_surChangementExterieur);
    _national.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Sépare l'indicatif connu du numéro national ; sinon le texte est gardé tel quel.
  void _decomposer(String brut) {
    final n = nettoyerTelephone(brut);
    for (final MapEntry(key: pays, value: indicatif) in _indicatifs.entries) {
      for (final prefixe in ['+$indicatif', '00$indicatif']) {
        if (n.startsWith(prefixe)) {
          _pays = pays;
          _national.text = n.substring(prefixe.length);
          _dernierEcrit = brut;
          return;
        }
      }
    }
    _pays = _indicatifs.containsKey(widget.paysInitial) ? widget.paysInitial : 'SN';
    _national.text = brut;
    _dernierEcrit = brut;
  }

  void _surChangementExterieur() {
    if (widget.controller.text == _dernierEcrit) return;
    setState(() {
      _decomposer(widget.controller.text);
      _generation++;
    });
  }

  /// Numéro complet ; un « 0 » national en tête (06…, 07…) est retiré, un numéro
  /// déjà saisi avec son indicatif (+…, 00…) est conservé tel quel.
  String get _numeroComplet {
    final n = nettoyerTelephone(_national.text);
    if (n.isEmpty || n.startsWith('+') || n.startsWith('00')) return n;
    return '+${_indicatifs[_pays]}${n.replaceFirst(RegExp(r'^0'), '')}';
  }

  void _publier(FormFieldState<String> etat) {
    final complet = _numeroComplet;
    _dernierEcrit = complet;
    widget.controller.text = complet;
    etat.didChange(complet);
    widget.onChanged?.call(complet);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ?? InputDecoration(labelText: widget.label, hintText: widget.hint);
    return FormField<String>(
      validator: widget.validator == null ? null : (_) => widget.validator!(_numeroComplet),
      // Le paquet n'expose pas onTapOutside : toucher ailleurs ferme le pavé téléphonique,
      // uniquement si ce champ est actif (sinon un toucher sur un autre champ, ou sur une
      // liste de suggestions, retirerait le focus à celui-ci)
      builder: (etat) => TapRegion(
        onTapOutside: (_) {
          if (_focus.hasFocus) _focus.unfocus();
        },
        child: IntlPhoneField(
          key: ValueKey(_generation),
          controller: _national,
          focusNode: _focus,
          countries: _paysTelephone,
          initialCountryCode: _pays,
          languageCode: LangueApp.instance.estAnglais ? 'en' : 'fr',
          disableLengthCheck: true,
          autovalidateMode: AutovalidateMode.disabled,
          dropdownIconPosition: IconPosition.trailing,
          dropdownIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.kPrimary, size: 20),
          flagsButtonPadding: const EdgeInsets.only(left: 12),
          dropdownTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
          pickerDialogStyle: PickerDialogStyle(
            searchFieldInputDecoration: InputDecoration(labelText: tr('Rechercher un pays')),
          ),
          decoration: decoration.copyWith(errorText: etat.errorText, counterText: ''),
          onCountryChanged: (c) {
            _pays = c.code;
            _publier(etat);
          },
          onChanged: (_) => _publier(etat),
        ),
      ),
    );
  }
}
