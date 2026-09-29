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
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

class _VilleOption {
  final String id;
  final String nom;
  const _VilleOption(this.id, this.nom);
  factory _VilleOption.fromJson(Map<String, dynamic> j) =>
      _VilleOption(j['id'] as String, j['nom'] as String? ?? '');
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

  bool get _isPasswordValid =>
      _hasUpperCase && _hasDigit && _hasSpecialChar && _hasMinLength;

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
      context.read<AuthBloc>().add(RegisterRequested(
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
        codeParrainage: _parrainageController.text.trim().isEmpty ? null : _parrainageController.text.trim().toUpperCase(),
      ));
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess || state is RegisterSuccess) {
            // Le compte doit être activé par le lien reçu par email avant la première connexion
            final email = _emailController.text.trim();
            final message = state is RegisterSuccess ? state.message : null;
            context.read<AuthBloc>().add(ResetAuthState());
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => VerificationEmailPage(email: email, message: message)),
              (route) => route.settings.name == AppRouter.clientRoute || route.isFirst,
            );
          } else if (state is AuthFailure) {
            showToast(context, tr('Échec de l\'inscription'), state.message, ToastificationType.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset('assets/images/logo_yobante_icon.png', width: 100, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('Créer un compte'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('Rejoignez Yobante Express pour suivre vos envois'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40),
                    ),
                    const SizedBox(height: 28),
                    _buildField(tr('Prénom'), tr('Ex: Mamadou'), _prenomController, Icons.person_outline,
                        maxLength: 50, validator: texte(requis: true, min: 2, max: 50)),
                    const SizedBox(height: 16),
                    _buildField(tr('Nom'), tr('Ex: Diallo'), _nomController, Icons.person_outline,
                        maxLength: 50, validator: texte(requis: true, min: 2, max: 50)),
                    const SizedBox(height: 16),
                    _buildField(tr('Adresse e-mail'), 'exemple@gmail.com', _emailController, Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 150,
                        validator: email()),
                    const SizedBox(height: 16),
                    _buildField(tr('Téléphone'), tr('Ex: 77 123 45 67 ou 06 12 34 56 78'), _telephoneController, Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: validerTelephone),
                    const SizedBox(height: 20),

                    Text(tr('Pays'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'SN', label: Text(tr('Sénégal'), style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'FR', label: Text(tr('France'), style: TextStyle(fontSize: 12))),
                      ],
                      selected: {_pays},
                      onSelectionChanged: (s) {
                        setState(() => _pays = s.first);
                        _chargerVilles();
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(tr('Ville (optionnel)'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
                    const SizedBox(height: 8),
                    if (_chargementVilles)
                      const LinearProgressIndicator()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(14)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<_VilleOption>(
                            isExpanded: true,
                            value: _ville,
                            hint: Text(tr('Sélectionner une ville'), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40)),
                            items: _villes.map((v) => DropdownMenuItem(value: v, child: Text(v.nom))).toList(),
                            onChanged: (v) => setState(() => _ville = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildField(tr('Adresse (optionnel)'), tr('Ex: Rue 10, Médina'), _adresseController, Icons.location_on_outlined,
                        maxLength: 255, validator: texte(max: 255)),
                    const SizedBox(height: 16),
                    _buildField(tr('Code postal (optionnel)'), tr('Pour être prévenu des collectes près de chez vous'),
                        _codePostalController, Icons.markunread_mailbox_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 10, validator: codePostal(pays: _pays)),
                    const SizedBox(height: 16),
                    _buildField(tr('Code de parrainage (optionnel)'), tr('Ex: K7P2QX9M'), _parrainageController,
                        Icons.card_giftcard_outlined, maxLength: 12, validator: texte(max: 12)),
                    const SizedBox(height: 20),

                    Text(tr('Type de compte'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'particulier', label: Text(tr('Particulier'), style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'entreprise', label: Text(tr('Entreprise'), style: TextStyle(fontSize: 12))),
                      ],
                      selected: {_typeCompte},
                      onSelectionChanged: (s) => setState(() => _typeCompte = s.first),
                    ),

                    if (_typeCompte == 'entreprise') ...[
                      const SizedBox(height: 16),
                      _buildField(tr('Raison sociale'), tr('Nom de l\'entreprise'), _raisonSocialeController, Icons.apartment_outlined,
                          maxLength: 150,
                          validator: texte(requis: true, max: 150, message: tr('Requis pour un compte entreprise'))),
                      const SizedBox(height: 16),
                      _buildField(tr('Numéro d\'identification fiscale (optionnel)'), tr('NINEA / SIRET'), _ninController, Icons.badge_outlined,
                          maxLength: 30, validator: texte(max: 30)),
                      const SizedBox(height: 16),
                      _buildField(tr('Numéro de TVA intracommunautaire (optionnel)'), tr('Ex: FR12345678900'), _tvaController, Icons.receipt_long_outlined,
                          maxLength: 20, validator: texte(max: 20)),
                    ],

                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text(tr("S'inscrire"), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: tr('Déjà un compte ? '), style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40, fontSize: 14)),
                          TextSpan(text: tr('Se connecter'), style: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                        ])),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
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
        Text(tr('Mot de passe'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (f) => setState(() => _passwordFocused = f),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: _checkPasswordStrength,
            inputFormatters: [LengthLimitingTextInputFormatter(72)],
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
            decoration: _inputDecoration(tr('Créez un mot de passe sécurisé'), Icons.lock_outline_rounded).copyWith(
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColor.kGrayscale40, size: 20),
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
            decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Critères :'), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
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
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: met ? const Color(0xFF22C55E) : AppColor.kErreur),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: met ? const Color(0xFF22C55E) : AppColor.kErreur)),
      ]),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40),
      prefixIcon: Icon(icon, color: AppColor.kPrimary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColor.kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColor.kErreur, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColor.kErreur, width: 1.5)),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kErreur),
    );
  }
}
