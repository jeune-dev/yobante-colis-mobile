import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/api_error.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../../core/i18n/langue.dart';
import '../widgets/mise_en_page_auth.dart';

/// Après l'inscription, le compte doit être activé par le lien envoyé par
/// email : le backend refuse la connexion tant que l'adresse n'est pas confirmée.
class VerificationEmailPage extends StatefulWidget {
  final String email;

  /// Message du backend à l'inscription (« Compte créé. Un lien… ») ; absent quand
  /// la page est ouverte depuis la connexion.
  final String? message;
  const VerificationEmailPage({super.key, required this.email, this.message});

  /// Demande un nouveau lien de confirmation (réponse identique que le compte existe ou non).
  static Future<String> renvoyerLien(String email) async {
    try {
      final res = await sl<Dio>().post(
        Env.authResendVerification,
        data: {'email': email},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      return messageApi(res);
    } on DioException catch (e) {
      throw Exception(messageErreur(e, tr('Envoi impossible pour le moment.')));
    }
  }

  /// Jeton de confirmation (64 caractères hexadécimaux) extrait du lien reçu par
  /// email (`…/auth/verify-email/<jeton>` ou `…/verifier-email?token=<jeton>`) ou saisi tel quel.
  static String? extraireJeton(String saisie) =>
      RegExp(r'(?<![0-9a-fA-F])[0-9a-fA-F]{64}(?![0-9a-fA-F])').firstMatch(saisie.trim())?.group(0)?.toLowerCase();

  /// Confirme l'adresse depuis l'application (`POST /auth/verify-email`).
  static Future<String> confirmer(String jeton) async {
    try {
      final res = await sl<Dio>().post(
        Env.authVerifyEmail,
        data: {'token': jeton},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      return messageApi(res);
    } on DioException catch (e) {
      throw Exception(messageErreur(e, tr('Lien de confirmation invalide ou expiré')));
    }
  }

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _envoi = false;
  bool _confirmation = false;
  final _lien = TextEditingController();

  @override
  void dispose() {
    _lien.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    final jeton = VerificationEmailPage.extraireJeton(_lien.text);
    if (jeton == null) {
      showToast(context, tr('Lien invalide'), tr('Collez le lien complet reçu par email.'), ToastificationType.warning);
      return;
    }
    setState(() => _confirmation = true);
    try {
      final message = await VerificationEmailPage.confirmer(jeton);
      if (!mounted) return;
      showToast(context, tr('Email confirmé'), message, ToastificationType.success);
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
    } catch (e) {
      if (mounted) {
        showToast(context, tr('Erreur'), e.toString().replaceFirst('Exception: ', ''), ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _confirmation = false);
    }
  }

  Future<void> _renvoyer() async {
    setState(() => _envoi = true);
    try {
      final message = await VerificationEmailPage.renvoyerLien(widget.email);
      if (mounted) showToast(context, tr('Lien envoyé'), message, ToastificationType.success);
    } catch (e) {
      if (mounted) {
        showToast(context, tr('Erreur'), e.toString().replaceFirst('Exception: ', ''), ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message ?? '';
    return MiseEnPageAuth(
      icone: Icons.mark_email_unread_outlined,
      titre: tr('Vérifiez votre boîte mail'),
      sousTitre: message.isNotEmpty
          ? message
          : tr('Cliquez sur le lien reçu pour activer votre compte, puis connectez-vous.'),
      enfants: [
        CarteAuth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Adresse à laquelle le lien a été envoyé
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
                          Text(tr('Lien envoyé à'), style: texteDiscret(11)),
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
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(tr('J\'ai confirmé, me connecter')),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _envoi ? null : _renvoyer,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: _envoi
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr('Renvoyer le lien')),
              ),
            ],
          ),
        ),
        CarteAuth(
          titre: tr('Le lien ne s\'ouvre pas ?'),
          icone: Icons.link_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Copiez le lien de l\'email et collez-le ici pour confirmer votre adresse.'),
                style: texteDiscret(13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lien,
                decoration: InputDecoration(
                  hintText: tr('Lien de confirmation'),
                  prefixIcon: const Icon(Icons.content_paste_rounded),
                ),
                onSubmitted: (_) => _confirmer(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _confirmation ? null : _confirmer,
                child: _confirmation
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        tr('Confirmer mon adresse'),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
