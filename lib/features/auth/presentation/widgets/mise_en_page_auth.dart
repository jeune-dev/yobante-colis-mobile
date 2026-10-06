import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';

/// Mise en page commune des écrans de connexion et d'inscription : en-tête bleu
/// marine (pictogramme, titre, trait jaune), puis le contenu posé à cheval sur
/// l'en-tête, le tout dans un seul défilement.
class MiseEnPageAuth extends StatelessWidget {
  final String titre;
  final String sousTitre;

  /// Pictogramme de contexte (cadenas, enveloppe…) à la place du logo.
  final IconData? icone;

  /// Cartes et liens placés sous l'en-tête.
  final List<Widget> enfants;

  const MiseEnPageAuth({super.key, required this.titre, required this.sousTitre, required this.enfants, this.icone});

  /// Chevauchement du contenu sur l'en-tête.
  static const double _chevauchement = 36;

  @override
  Widget build(BuildContext context) {
    // En-tête bleu : icônes de la barre d'état en blanc
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _EnteteAuth(titre: titre, sousTitre: sousTitre, icone: icone),
              Transform.translate(
                offset: const Offset(0, -_chevauchement),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: enfants),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnteteAuth extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData? icone;
  const _EnteteAuth({required this.titre, required this.sousTitre, this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 24, MiseEnPageAuth._chevauchement + 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: tr('Retour'),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.kWhite, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
                      child: icone == null
                          ? Image.asset('assets/images/logo_yobante_icon.png', width: 36, height: 36)
                          : SizedBox(width: 36, height: 36, child: Icon(icone, color: AppColor.kPrimary, size: 26)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      titre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kWhite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sousTitre,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kWhite.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte blanche d'un formulaire d'authentification, avec un titre de section facultatif.
class CarteAuth extends StatelessWidget {
  final String? titre;
  final IconData? icone;
  final Widget child;
  const CarteAuth({super.key, this.titre, this.icone, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titre != null) ...[
            Row(
              children: [
                if (icone != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icone, size: 16, color: AppColor.kPrimary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    titre!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Libellé d'un champ de formulaire.
class LibelleChamp extends StatelessWidget {
  final String texte;
  const LibelleChamp(this.texte, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      texte,
      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: AppColor.kGrayscaleDark100),
    ),
  );
}

/// Lien « Pas encore de compte ? / Déjà un compte ? » sous les cartes.
class LienAuth extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;
  const LienAuth({super.key, required this.question, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40, fontSize: 14)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: Text(
            action,
            style: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
