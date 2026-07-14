import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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
  bool _obscurePassword = true;

  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordFocused = false;

  bool get _isPasswordValid =>
      _hasUpperCase && _hasLowerCase && _hasDigit && _hasSpecialChar && _hasMinLength;

  void _checkPasswordStrength(String value) {
    setState(() {
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasDigit = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]'));
      _hasMinLength = value.length >= 8;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterRequested(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        motDePasse: _passwordController.text,
        telephone: _telephoneController.text.trim(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess || state is RegisterSuccess) {
            showToast(context, 'Inscription réussie', 'Vous pouvez maintenant vous connecter !', ToastificationType.success);
            Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
            context.read<AuthBloc>().add(ResetAuthState());
          } else if (state is AuthFailure) {
            showToast(context, 'Échec de l\'inscription', state.message, ToastificationType.error);
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
                      child: Image.asset('assets/images/logosignapk.jpeg', width: 100, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Créer un compte',
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: AppColor.kGrayscaleDark100),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rejoignez Yobnate Colis pour suivre vos envois',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscale40),
                    ),
                    const SizedBox(height: 28),
                    _buildField('Prénom', 'Ex: Mamadou', _prenomController, Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null),
                    const SizedBox(height: 16),
                    _buildField('Nom', 'Ex: Diallo', _nomController, Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null),
                    const SizedBox(height: 16),
                    _buildField('Adresse e-mail', 'exemple@gmail.com', _emailController, Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Champ requis';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email invalide';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _buildField('Téléphone', 'Ex: 771234567', _telephoneController, Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null),
                    const SizedBox(height: 16),
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
                            : Text("S'inscrire", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Déjà un compte ? ', style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40, fontSize: 14)),
                          TextSpan(text: 'Se connecter', style: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
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
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mot de passe', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100)),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (f) => setState(() => _passwordFocused = f),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: _checkPasswordStrength,
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
            decoration: _inputDecoration('Créez un mot de passe sécurisé', Icons.lock_outline_rounded).copyWith(
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColor.kGrayscale40, size: 20),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Champ requis';
              if (!_isPasswordValid) return 'Le mot de passe ne respecte pas tous les critères';
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
                Text('Critères :', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                _criteriaRow('Au moins 8 caractères', _hasMinLength),
                _criteriaRow('Une majuscule (A–Z)', _hasUpperCase),
                _criteriaRow('Une minuscule (a–z)', _hasLowerCase),
                _criteriaRow('Un chiffre (0–9)', _hasDigit),
                _criteriaRow('Un caractère spécial (!@#\$%...)', _hasSpecialChar),
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
        Icon(met ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: met ? const Color(0xFF22C55E) : Colors.redAccent),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: met ? const Color(0xFF22C55E) : Colors.redAccent)),
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
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.redAccent),
    );
  }
}
