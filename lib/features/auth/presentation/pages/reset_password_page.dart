import 'dart:async';
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
import '../../../../injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_page.dart';

/// Étape 2 : code à 6 chiffres reçu par email, puis nouveau mot de passe.
///
/// Le code expire et est invalidé après plusieurs erreurs (règles du backend) :
/// l'utilisateur peut en redemander un sans revenir en arrière.
class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const _delaiRenvoi = 60;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _soumis = false;
  bool _masquer = true;
  bool _renvoiEnCours = false;
  int _attente = _delaiRenvoi;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _demarrerAttente();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _code.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  /// Un code vient d'être envoyé : le suivant n'est proposé qu'après un délai.
  void _demarrerAttente() {
    _minuteur?.cancel();
    setState(() => _attente = _delaiRenvoi);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _attente--);
      if (_attente <= 0) t.cancel();
    });
  }

  /// Nouveau code, sans passer par AuthBloc (l'écran précédent y réagirait).
  Future<void> _renvoyerCode() async {
    setState(() => _renvoiEnCours = true);
    final resultat = await sl<AuthRepository>().forgotPassword(widget.email);
    if (!mounted) return;
    setState(() => _renvoiEnCours = false);
    resultat.fold(
      (f) => showToast(context, tr('Erreur'), f.errorMessage, ToastificationType.error),
      (message) {
        _code.clear();
        _demarrerAttente();
        if (message.isNotEmpty) showToast(context, tr('Email envoyé'), message, ToastificationType.success);
      },
    );
  }

  void _valider() {
    setState(() => _soumis = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(ResetPasswordRequested(
          email: widget.email,
          otpRecu: _code.text.trim(),
          newPassword: _nouveau.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? false,
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          if (state.message.isNotEmpty) {
            showToast(context, tr('Mot de passe modifié'), state.message, ToastificationType.success);
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.loginRoute,
            (route) => route.settings.name == AppRouter.clientRoute || route.isFirst,
          );
        } else if (state is AuthFailure) {
          showToast(context, tr('Erreur'), state.message, ToastificationType.error);
        }
      },
      child: EcranMotDePasse(
        icone: Icons.password_rounded,
        titre: tr('Nouveau mot de passe'),
        sousTitre: tr('Saisissez le code reçu par email, puis choisissez votre nouveau mot de passe.'),
        child: Form(
          key: _formKey,
          autovalidateMode: _soumis ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CarteEmail(email: widget.email),
              const SizedBox(height: 20),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: InputDecoration(labelText: tr('Code à 6 chiffres'), counterText: ''),
                validator: codeSixChiffres,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _attente > 0 || _renvoiEnCours ? null : _renvoyerCode,
                  icon: _renvoiEnCours
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _attente > 0 ? tr('Renvoyer le code dans $_attente s') : tr('Renvoyer le code'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nouveau,
                obscureText: _masquer,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(72)],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr('Nouveau mot de passe'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_masquer ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _masquer = !_masquer),
                  ),
                ),
                validator: motDePasse,
              ),
              const SizedBox(height: 10),
              _Criteres(motDePasse: _nouveau.text),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmation,
                obscureText: _masquer,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _valider(),
                decoration: InputDecoration(
                  labelText: tr('Confirmer le mot de passe'),
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                ),
                validator: (v) => v != _nouveau.text ? tr('Les mots de passe ne correspondent pas') : null,
              ),
              const SizedBox(height: 28),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => BoutonPrincipal(
                  libelle: tr('Enregistrer le mot de passe'),
                  chargement: state is AuthLoading,
                  onPressed: _valider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rappel de l'adresse à laquelle le code a été envoyé, avec retour pour la corriger.
class _CarteEmail extends StatelessWidget {
  final String email;
  const _CarteEmail({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColor.kBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, size: 20, color: AppColor.kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
            ),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('Modifier'))),
        ],
      ),
    );
  }
}

/// Critères du backend, cochés au fil de la saisie.
class _Criteres extends StatelessWidget {
  final String motDePasse;
  const _Criteres({required this.motDePasse});

  @override
  Widget build(BuildContext context) {
    Widget critere(String libelle, bool ok) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16, color: ok ? AppColor.kSucces : AppColor.kGrayscale40),
            const SizedBox(width: 8),
            Text(
              libelle,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: ok ? AppColor.kSucces : AppColor.kGrayscale40),
            ),
          ]),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        critere(tr('8 à 72 caractères'), RegleMotDePasse.longueur(motDePasse)),
        critere(tr('Une majuscule (A–Z)'), RegleMotDePasse.majuscule(motDePasse)),
        critere(tr('Un chiffre (0–9)'), RegleMotDePasse.chiffre(motDePasse)),
        critere(tr('Un caractère spécial'), RegleMotDePasse.special(motDePasse)),
      ],
    );
  }
}
