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
import '../widgets/mise_en_page_auth.dart';
import '../widgets/password_text_field.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

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
    context.read<AuthBloc>().add(
      LoginRequested(
        // Un numéro est normalisé au format international attendu par le backend
        identifiant: saisie.contains('@') ? saisie : normaliserTelephone(saisie),
        motDePasse: _passwordCtrl.text,
      ),
    );
  }

  /// Compte existant mais email non confirmé : proposer de renvoyer le lien.
  Future<void> _compteNonConfirme(String message) async {
    final saisie = _emailCtrl.text.trim();
    final email = TextEditingController(text: saisie.contains('@') ? saisie : '');
    final choix = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Email non confirmé')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: tr('Votre email')),
            ),
          ],
        ),
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
      // AuthBloc est partagé : les erreurs du mot de passe oublié (écrans ouverts
      // par-dessus) ne doivent pas s'afficher ici en « Erreur de connexion »
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? false,
      listener: (context, state) {
        if (state is AuthFailure && state.emailNonConfirme) {
          _compteNonConfirme(state.message);
          return;
        }
        if (state is AuthFailure) {
          showToast(context, tr('Erreur de connexion'), state.message, ToastificationType.error);
        }
        if (state is AuthSuccess) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (r) => false);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        // Ouvert seul (session expirée, lien de confirmation…) : le retour mène
        // à l'accueil en invité plutôt que de bloquer sur la connexion.
        final peutRevenir = Navigator.of(context).canPop();
        return PopScope(
          canPop: peutRevenir,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
          },
          child: _contenu(context, isLoading),
        );
      },
    );
  }

  Widget _contenu(BuildContext context, bool isLoading) {
    return MiseEnPageAuth(
      titre: tr('Bon retour !'),
      sousTitre: tr('Connectez-vous pour accéder à vos colis.'),
      enfants: [
        CarteAuth(child: _formulaire(context, isLoading)),
        LienAuth(
          question: tr('Pas encore de compte ? '),
          action: tr('Créer un compte'),
          onTap: () => Navigator.of(context).pushNamed(AppRouter.registerRoute),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _formulaire(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LibelleChamp(tr('Email ou téléphone')),
          PrimaryTextFormField(
            hintText: tr('Votre email ou numéro'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColor.kPrimary, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return tr('Email ou téléphone requis');
              }
              if (v.contains('@') ? email()(v) != null : validerTelephone(v) != null) {
                return tr('Email ou numéro de téléphone invalide');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          LibelleChamp(tr('Mot de passe')),
          PasswordTextField(
            controller: _passwordCtrl,
            hintText: tr('Votre mot de passe'),
            validator: (v) {
              if (v == null || v.isEmpty) return tr('Mot de passe requis');
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.forgotPasswordRoute, arguments: _emailCtrl.text.trim()),
              child: Text(
                tr('Mot de passe oublié ?'),
                style: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            text: tr('Se connecter'),
            onTap: isLoading ? null : _submit,
            isLoading: isLoading,
            bgColor: AppColor.kPrimary,
            textColor: AppColor.kWhite,
          ),
        ],
      ),
    );
  }
}
