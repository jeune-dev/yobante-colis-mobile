import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/validateurs.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Étape 1 : l'utilisateur saisit son email, le backend envoie un code à 6 chiffres.
///
/// Le backend répond toujours de la même façon, que le compte existe ou non :
/// on passe donc à l'étape 2 dans tous les cas, avec son message.
class ForgotPasswordPage extends StatefulWidget {
  /// Email déjà saisi sur l'écran de connexion, repris ici.
  final String? email;
  const ForgotPasswordPage({super.key, this.email});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: (widget.email ?? '').contains('@') ? widget.email : '');
  bool _soumis = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _envoyer() {
    setState(() => _soumis = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(ForgotPasswordRequested(email: _email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // AuthBloc est partagé par toute l'application : seul l'écran visible réagit
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? false,
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          if (state.message.isNotEmpty) {
            showToast(context, tr('Email envoyé'), state.message, ToastificationType.success);
          }
          Navigator.of(context).pushNamed(AppRouter.resetPasswordRoute, arguments: _email.text.trim());
        } else if (state is AuthFailure) {
          showToast(context, tr('Erreur'), state.message, ToastificationType.error);
        }
      },
      child: EcranMotDePasse(
        icone: Icons.lock_reset_rounded,
        titre: tr('Mot de passe oublié ?'),
        sousTitre: tr('Saisissez l\'adresse email de votre compte : nous vous enverrons un code pour choisir un nouveau mot de passe.'),
        child: Form(
          key: _formKey,
          autovalidateMode: _soumis ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _envoyer(),
                inputFormatters: [LengthLimitingTextInputFormatter(150)],
                decoration: InputDecoration(
                  labelText: tr('Adresse email'),
                  hintText: 'exemple@email.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                validator: email(),
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => BoutonPrincipal(
                  libelle: tr('Recevoir un code'),
                  chargement: state is AuthLoading,
                  onPressed: _envoyer,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('Retour à la connexion')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mise en page commune aux deux étapes (email, puis code et nouveau mot de passe).
class EcranMotDePasse extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final Widget child;
  const EcranMotDePasse({
    super.key,
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      appBar: AppBar(backgroundColor: AppColor.kWhite, elevation: 0, scrolledUnderElevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColor.kSecondaryLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icone, size: 42, color: AppColor.kPrimary),
                ),
              ),
              const SizedBox(height: 24),
              Text(titre, textAlign: TextAlign.center, style: titreSection(24)),
              const SizedBox(height: 8),
              Text(
                sousTitre,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: AppColor.kGrayscale40),
              ),
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton plein de l'écran, avec indicateur pendant l'envoi.
class BoutonPrincipal extends StatelessWidget {
  final String libelle;
  final bool chargement;
  final VoidCallback onPressed;
  const BoutonPrincipal({super.key, required this.libelle, required this.chargement, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: chargement ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: chargement
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(libelle, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
