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

/// Après l'inscription, le compte doit être activé par le lien envoyé par
/// email : le backend refuse la connexion tant que l'adresse n'est pas confirmée.
class VerificationEmailPage extends StatefulWidget {
  final String email;
  const VerificationEmailPage({super.key, required this.email});

  /// Demande un nouveau lien de confirmation (réponse identique que le compte existe ou non).
  static Future<String> renvoyerLien(String email) async {
    try {
      final res = await sl<Dio>().post(
        Env.authResendVerification,
        data: {'email': email},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );
      return res.data['message'] as String? ?? tr('Un nouveau lien vous a été envoyé.');
    } on DioException catch (e) {
      throw Exception(messageErreur(e, tr('Envoi impossible pour le moment.')));
    }
  }

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _envoi = false;

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
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      appBar: AppBar(title: Text(tr('Confirmez votre email'))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_unread_outlined, size: 48, color: AppColor.kPrimary),
            ),
          ),
          const SizedBox(height: 24),
          Text(tr('Vérifiez votre boîte mail'), textAlign: TextAlign.center, style: titreSection(22)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: tr('Nous avons envoyé un lien de confirmation à\n')),
              TextSpan(text: widget.email, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              TextSpan(text: tr('.\nCliquez dessus pour activer votre compte, puis connectez-vous.')),
            ]),
            textAlign: TextAlign.center,
            style: texteDiscret(14),
          ),
          const SizedBox(height: 8),
          Text(tr('Pensez à regarder dans vos courriers indésirables.'), textAlign: TextAlign.center, style: texteDiscret(12)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(tr('J\'ai confirmé, me connecter')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _envoi ? null : _renvoyer,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _envoi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(tr('Renvoyer le lien')),
          ),
        ]),
      ),
    );
  }
}
