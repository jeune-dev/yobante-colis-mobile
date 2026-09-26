import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import 'verification_email_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/primary_text_form_field.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/password_text_field.dart';
import '../../../../core/i18n/langue.dart';

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
    final saisie = _emailCtrl.text.trim();
    context.read<AuthBloc>().add(LoginRequested(
          // Un numéro est normalisé au format international attendu par le backend
          identifiant: saisie.contains('@') ? saisie : normaliserTelephone(saisie),
          motDePasse: _passwordCtrl.text,
        ));
  }

  /// Compte existant mais email non confirmé : proposer de renvoyer le lien.
  Future<void> _compteNonConfirme(String message) async {
    final saisie = _emailCtrl.text.trim();
    final email = TextEditingController(text: saisie.contains('@') ? saisie : '');
    final choix = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Email non confirmé')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: tr('Votre email'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Fermer'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Renvoyer le lien'))),
        ],
      ),
    );
    if (choix != true || !mounted || !email.text.contains('@')) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VerificationEmailPage(email: email.text.trim())));
    VerificationEmailPage.renvoyerLien(email.text.trim()).catchError((_) => '');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure && state.message.contains('non confirmée')) {
          _compteNonConfirme(state.message);
          return;
        }
        if (state is AuthFailure) {
          showToast(
            context,
            tr('Erreur de connexion'),
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
            title: Text(tr('Connexion')),
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
                      tr('Bon retour !'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('Connectez-vous pour accéder à vos colis.'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      tr('Email ou téléphone'),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryTextFormField(
                      hintText: tr('exemple@email.com ou 77 123 45 67'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppColor.kGrayscale40, size: 20),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return tr('Email ou téléphone requis');
                        }
                        if (!v.contains('@') && validerTelephone(v) != null) {
                          return tr('Email ou numéro de téléphone invalide');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('Mot de passe'),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PasswordTextField(
                      controller: _passwordCtrl,
                      hintText: '••••••••',
                      validator: (v) {
                        if (v == null || v.isEmpty) return tr('Mot de passe requis');
                        if (v.length < 6) return tr('Minimum 6 caractères');
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
                          tr('Mot de passe oublié ?'),
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
                      text: tr('Se connecter'),
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
                          tr('Pas encore de compte ? '),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColor.kGrayscale40,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRouter.registerRoute),
                          child: Text(
                            tr('S\'inscrire'),
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

