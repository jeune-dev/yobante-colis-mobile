import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/primary_text_form_field.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/password_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(
          identifiant: _emailCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showToast(
            context,
            'Erreur de connexion',
            state.message,
            ToastificationType.error,
          );
        }
        if (state is AuthSuccess) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.clientRoute, (r) => false);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColor.kWhite,
          appBar: AppBar(
            title: const Text('Connexion'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Bon retour ! ðŸ‘‹',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour accÃ©der Ã  vos colis.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Email',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryTextFormField(
                      hintText: 'exemple@email.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppColor.kGrayscale40, size: 20),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Mot de passe',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PasswordTextField(
                      controller: _passwordCtrl,
                      hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 6) return 'Minimum 6 caractÃ¨res';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRouter.forgotPasswordRoute),
                        child: Text(
                          'Mot de passe oubliÃ© ?',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColor.kPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: 'Se connecter',
                      onTap: isLoading ? null : _submit,
                      isLoading: isLoading,
                      bgColor: AppColor.kPrimary,
                      textColor: AppColor.kWhite,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColor.kGrayscale40,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRouter.registerRoute),
                          child: Text(
                            'S\'inscrire',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColor.kPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

