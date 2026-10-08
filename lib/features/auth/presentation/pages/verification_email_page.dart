import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/validateurs.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/mise_en_page_auth.dart';

/// Confirmation de l'adresse email, étape obligatoire entre l'inscription et
/// l'accès à l'application (même mécanisme que SIGNS) : le compte existe mais
/// reste fermé tant que le code à 6 chiffres reçu par email n'a pas été saisi.
/// C'est cette confirmation qui ouvre la session — le backend n'émet aucun jeton
/// avant, et refuse la connexion (403 EMAIL_NON_CONFIRME).
class VerificationEmailPage extends StatefulWidget {
  final String email;

  /// Message du backend à l'inscription ; absent quand la page est ouverte depuis la connexion.
  final String? message;

  /// Faux quand l'envoi a échoué à l'inscription, ou depuis la connexion (le code
  /// d'origine a pu expirer) : le renvoi est alors proposé tout de suite.
  final bool codeEnvoye;

  const VerificationEmailPage({super.key, required this.email, this.message, this.codeEnvoye = true});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _renvoi = false;

  /// Attente avant de pouvoir redemander un code : sans elle, des appuis répétés
  /// sur « Renvoyer » déclencheraient autant d'emails.
  int _secondesAvantRenvoi = 0;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    if (widget.codeEnvoye) _demarrerAttenteRenvoi();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _demarrerAttenteRenvoi() {
    _minuteur?.cancel();
    setState(() => _secondesAvantRenvoi = 60);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondesAvantRenvoi -= 1);
      if (_secondesAvantRenvoi <= 0) t.cancel();
    });
  }

  void _verifier() {
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(VerificationEmailRequested(email: widget.email, code: _code.text.trim()));
  }

  Future<void> _renvoyer() async {
    setState(() => _renvoi = true);
    final resultat = await sl<AuthRepository>().renvoyerCodeVerification(widget.email);
    if (!mounted) return;
    setState(() => _renvoi = false);
    resultat.fold(
      (f) => showToast(context, tr('Envoi impossible'), f.errorMessage, ToastificationType.error),
      (message) {
        _demarrerAttenteRenvoi();
        showToast(context, tr('Code renvoyé'), message, ToastificationType.info);
      },
    );
  }

  void _retourConnexion() => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? false,
      listener: (context, state) {
        if (state is AuthSuccess) {
          showToast(context, tr('Compte activé'), tr('Bienvenue chez Yobante Colis !'), ToastificationType.success);
          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false);
        } else if (state is AuthFailure) {
          showToast(context, tr('Code refusé'), state.message, ToastificationType.error);
        }
      },
      builder: (context, state) => _contenu(state is AuthLoading),
    );
  }

  Widget _contenu(bool enCours) {
    final message = widget.message ?? '';
    return MiseEnPageAuth(
      icone: Icons.mark_email_unread_outlined,
      titre: tr('Vérifiez votre boîte mail'),
      sousTitre: message.isNotEmpty
          ? message
          : tr('Saisissez le code à 6 chiffres reçu par email pour activer votre compte.'),
      enfants: [
        CarteAuth(
          child: Form(
            key: _cleFormulaire,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Adresse à laquelle le code a été envoyé
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, color: AppColor.kPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Code envoyé à'), style: texteDiscret(11)),
                            const SizedBox(height: 2),
                            Text(
                              widget.email,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColor.kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColor.kGrayscale40),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(tr('Pensez à regarder dans vos courriers indésirables.'), style: texteDiscret(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LibelleChamp(tr('Code de confirmation')),
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                  decoration: const InputDecoration(hintText: '••••••'),
                  validator: codeSixChiffres,
                  onFieldSubmitted: (_) => _verifier(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: enCours ? null : _verifier,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: enCours
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(tr('Activer mon compte')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _renvoi || _secondesAvantRenvoi > 0 ? null : _renvoyer,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  icon: _renvoi
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _secondesAvantRenvoi > 0
                        ? tr('Renvoyer le code dans $_secondesAvantRenvoi s')
                        : tr('Renvoyer le code'),
                  ),
                ),
              ],
            ),
          ),
        ),
        LienAuth(
          question: tr('Déjà confirmé ? '),
          action: tr('Se connecter'),
          onTap: _retourConnexion,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
