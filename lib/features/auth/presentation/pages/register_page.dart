import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/config/env.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import 'verification_email_page.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/mise_en_page_auth.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

class _VilleOption {
  final String id;
  final String nom;
  const _VilleOption(this.id, this.nom);
  factory _VilleOption.fromJson(Map<String, dynamic> j) => _VilleOption(j['id'] as String, j['nom'] as String? ?? '');
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adresseController = TextEditingController();
  final _raisonSocialeController = TextEditingController();
  final _ninController = TextEditingController();
  final _tvaController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _parrainageController = TextEditingController();
  bool _obscurePassword = true;

  bool _hasUpperCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordFocused = false;

  String _pays = 'SN';
  String _typeCompte = 'particulier';
  List<_VilleOption> _villes = [];
  _VilleOption? _ville;
  bool _chargementVilles = true;

  bool get _isPasswordValid => _hasUpperCase && _hasDigit && _hasSpecialChar && _hasMinLength;

  @override
  void initState() {
    super.initState();
    _chargerVilles();
  }

  Future<void> _chargerVilles() async {
    setState(() {
      _chargementVilles = true;
      _ville = null;
    });
    try {
      final res = await sl<Dio>().get(Env.publicVilles, queryParameters: {'pays': _pays});
      final list = (res.data['data']['villes'] as List)
          .map((e) => _VilleOption.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _villes = list;
        _chargementVilles = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargementVilles = false);
    }
  }

  void _checkPasswordStrength(String value) {
    setState(() {
      // Règle du backend : majuscule, chiffre, caractère spécial, 8 à 72 caractères
      _hasUpperCase = RegleMotDePasse.majuscule(value);
      _hasDigit = RegleMotDePasse.chiffre(value);
      _hasSpecialChar = RegleMotDePasse.special(value);
      _hasMinLength = RegleMotDePasse.longueur(value);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          motDePasse: _passwordController.text,
          telephone: normaliserTelephone(_telephoneController.text, paysParDefaut: _pays),
          pays: _pays,
          villeId: _ville?.id,
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          typeCompte: _typeCompte,
          raisonSociale: _typeCompte == 'entreprise' && _raisonSocialeController.text.trim().isNotEmpty
              ? _raisonSocialeController.text.trim()
              : null,
          numeroIdentificationFiscale: _ninController.text.trim().isEmpty ? null : _ninController.text.trim(),
          numeroTvaIntracom: _tvaController.text.trim().isEmpty ? null : _tvaController.text.trim(),
          codePostal: _codePostalController.text.trim().isEmpty ? null : _codePostalController.text.trim(),
          codeParrainage: _parrainageController.text.trim().isEmpty
              ? null
              : _parrainageController.text.trim().toUpperCase(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _adresseController.dispose();
    _raisonSocialeController.dispose();
    _ninController.dispose();
    _tvaController.dispose();
    _codePostalController.dispose();
    _parrainageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess || state is RegisterSuccess) {
          // Le compte doit être activé par le lien reçu par email avant la première connexion
          final email = _emailController.text.trim();
          final message = state is RegisterSuccess ? state.message : null;
          context.read<AuthBloc>().add(ResetAuthState());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => VerificationEmailPage(email: email, message: message),
            ),
            (route) => route.settings.name == AppRouter.clientRoute || route.isFirst,
          );
        } else if (state is AuthFailure) {
          showToast(context, tr('Échec de l\'inscription'), state.message, ToastificationType.error);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Form(
          key: _formKey,
          child: MiseEnPageAuth(
            titre: tr('Créer un compte'),
            sousTitre: tr('Rejoignez Yobante Colis pour suivre vos envois'),
            enfants: [
              CarteAuth(
                titre: tr('Vos informations'),
                icone: Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prénom et nom côte à côte
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            tr('Prénom'),
                            tr('Ex: Mamadou'),
                            _prenomController,
                            null,
                            maxLength: 50,
                            validator: texte(requis: true, min: 2, max: 50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            tr('Nom'),
                            tr('Ex: Diallo'),
                            _nomController,
                            null,
                            maxLength: 50,
                            validator: texte(requis: true, min: 2, max: 50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      tr('Adresse e-mail'),
                      'exemple@gmail.com',
                      _emailController,
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 150,
                      validator: email(),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      tr('Téléphone'),
                      tr('Ex: 77 123 45 67'),
                      _telephoneController,
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: validerTelephone,
                    ),
                  ],
                ),
              ),
              CarteAuth(
                titre: tr('Où êtes-vous ?'),
                icone: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LibelleChamp(tr('Pays')),
                    _choix({'SN': tr('Sénégal'), 'FR': tr('France')}, _pays, (v) {
                      setState(() => _pays = v);
                      _chargerVilles();
                    }),
                    const SizedBox(height: 16),
                    LibelleChamp(tr('Ville (optionnel)')),
                    if (_chargementVilles)
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(color: AppColor.kPrimary, minHeight: 3),
                      )
                    else
                      DropdownButtonFormField<_VilleOption>(
                        initialValue: _ville,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.kPrimary),
                        decoration: _inputDecoration(tr('Sélectionner une ville'), Icons.location_city_outlined),
                        items: _villes.map((v) => DropdownMenuItem(value: v, child: Text(v.nom))).toList(),
                        onChanged: (v) => setState(() => _ville = v),
                      ),
                    const SizedBox(height: 16),
                    _buildField(
                      tr('Adresse (optionnel)'),
                      tr('Ex: Rue 10, Médina'),
                      _adresseController,
                      Icons.home_outlined,
                      maxLength: 255,
                      validator: texte(max: 255),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      tr('Code postal (optionnel)'),
                      tr('Ex: 75001'),
                      _codePostalController,
                      Icons.markunread_mailbox_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: codePostal(pays: _pays),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        tr('Pour être prévenu des collectes près de chez vous'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40),
                      ),
                    ),
                  ],
                ),
              ),
              CarteAuth(
                titre: tr('Type de compte'),
                icone: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _choix(
                      {'particulier': tr('Particulier'), 'entreprise': tr('Entreprise')},
                      _typeCompte,
                      (v) => setState(() => _typeCompte = v),
                    ),
                    if (_typeCompte == 'entreprise') ...[
                      const SizedBox(height: 16),
                      _buildField(
                        tr('Raison sociale'),
                        tr('Nom de l\'entreprise'),
                        _raisonSocialeController,
                        Icons.apartment_outlined,
                        maxLength: 150,
                        validator: texte(requis: true, max: 150, message: tr('Requis pour un compte entreprise')),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        tr('Numéro d\'identification fiscale (optionnel)'),
                        tr('NINEA / SIRET'),
                        _ninController,
                        Icons.numbers_rounded,
                        maxLength: 30,
                        validator: texte(max: 30),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        tr('Numéro de TVA intracommunautaire (optionnel)'),
                        tr('Ex: FR12345678900'),
                        _tvaController,
                        Icons.receipt_long_outlined,
                        maxLength: 20,
                        validator: texte(max: 20),
                      ),
                    ],
                  ],
                ),
              ),
              CarteAuth(
                titre: tr('Sécurité'),
                icone: Icons.lock_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildField(
                      tr('Code de parrainage (optionnel)'),
                      tr('Ex: K7P2QX9M'),
                      _parrainageController,
                      Icons.card_giftcard_outlined,
                      maxLength: 12,
                      validator: texte(max: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: AppColor.kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColor.kWhite),
                        )
                      : Text(
                          tr('Créer mon compte'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              LienAuth(
                question: tr('Déjà un compte ? '),
                action: tr('Se connecter'),
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Choix entre deux options (pays, type de compte), aux couleurs de la marque.
  Widget _choix(Map<String, String> options, String valeur, ValueChanged<String> choisir) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: options.entries.map((o) {
          final choisi = o.key == valeur;
          return Expanded(
            child: GestureDetector(
              onTap: () => choisir(o.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: choisi ? AppColor.kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  o.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: choisi ? AppColor.kWhite : AppColor.kGrayscale40,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    IconData? icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(hint, icon),
          validator: validator,
          inputFormatters: maxLength == null ? null : [LengthLimitingTextInputFormatter(maxLength)],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(tr('Mot de passe')),
        Focus(
          onFocusChange: (f) => setState(() => _passwordFocused = f),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: _checkPasswordStrength,
            inputFormatters: [LengthLimitingTextInputFormatter(72)],
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(tr('Votre mot de passe'), Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColor.kGrayscale40,
                  size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return tr('Champ requis');
              if (!_isPasswordValid) return tr('Le mot de passe ne respecte pas tous les critères');
              return null;
            },
          ),
        ),
        if (_passwordController.text.isNotEmpty || _passwordFocused) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _criteriaRow(tr('8 à 72 caractères'), _hasMinLength),
                _criteriaRow(tr('Une majuscule (A–Z)'), _hasUpperCase),
                _criteriaRow(tr('Un chiffre (0–9)'), _hasDigit),
                _criteriaRow(tr('Un caractère spécial (!@#\$%...)'), _hasSpecialChar),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _criteriaRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: met ? AppColor.kSucces : AppColor.kGrayscale40,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: met ? FontWeight.w600 : FontWeight.w500,
              color: met ? AppColor.kSucces : AppColor.kGrayscaleDark100,
            ),
          ),
        ],
      ),
    );
  }

  /// Style du thème des formulaires (fond clair, contour fin, bleu au focus), comme la connexion.
  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColor.kPrimary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 2,
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kErreur),
    );
  }
}
