import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_color.dart';
import 'toast_notif.dart';
import '../i18n/langue.dart';

/// Composants visuels communs, dans l'esprit des applications de transporteur
/// express : cartes blanches aérées, titres courts, actions jaunes.

TextStyle titreSection([double taille = 15]) =>
    GoogleFonts.plusJakartaSans(fontSize: taille, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100);

TextStyle texteDiscret([double taille = 12]) =>
    GoogleFonts.plusJakartaSans(fontSize: taille, color: AppColor.kGrayscale40);

class CarteSection extends StatelessWidget {
  final String? titre;
  final IconData? icone;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Widget? action;
  const CarteSection({
    super.key,
    this.titre,
    this.icone,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // Fond blanc porté par un Material (et non par la décoration) : les ListTile
    // placés dans la carte y dessinent leur effet au toucher.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titre != null) ...[
                Row(
                  children: [
                    // Icône dans une pastille bleu clair, titre sombre (comme les cartes de connexion)
                    if (icone != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColor.kPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icone, size: 16, color: AppColor.kPrimary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        titre!,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColor.kGrayscaleDark100,
                        ),
                      ),
                    ),
                    ?action,
                  ],
                ),
                const SizedBox(height: 14),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class LigneInfo extends StatelessWidget {
  final String libelle;
  final String valeur;
  final bool fort;
  const LigneInfo(this.libelle, this.valeur, {super.key, this.fort = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne des libellés proportionnelle à l'écran (130 au plus)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width * 0.34).clamp(90.0, 130.0),
            child: Text(libelle, style: texteDiscret(13)),
          ),
          Expanded(
            child: Text(
              valeur,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fort ? 15 : 13,
                fontWeight: fort ? FontWeight.w700 : FontWeight.w600,
                color: fort ? AppColor.kPrimary : AppColor.kGrayscaleDark100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'information coloré (étude en cours, paiement attendu, refus…).
class Bandeau extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? message;
  final Color couleur;
  final Widget? action;
  const Bandeau({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.couleur = AppColor.kPrimary,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icone, color: couleur, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    titre,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: couleur),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(message!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscaleDark100)),
                ],
                if (action != null) ...[const SizedBox(height: 10), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de catégorie de colis (1, 2, 3).
class PastilleCategorie extends StatelessWidget {
  final int numero;
  final String libelle;
  const PastilleCategorie({super.key, required this.numero, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(20)),
      child: Text(
        tr('Cat. $numero · $libelle'),
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kPrimary),
      ),
    );
  }
}

/// Ouvre un lien externe (paiement, CGV, Chronopost…) dans le navigateur.
Future<void> ouvrirLien(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) {
    showToast(context, tr('Lien indisponible'), tr('Ce lien n\'est pas encore configuré.'), ToastificationType.info);
    return;
  }
  final uri = Uri.tryParse(url);
  final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showToast(context, tr('Erreur'), tr('Impossible d\'ouvrir le lien.'), ToastificationType.error);
  }
}

/// Ouvre une conversation WhatsApp avec le service client (ou un partage si [numero] est vide).
Future<void> ouvrirWhatsapp(BuildContext context, {String? numero, String? message}) {
  final chiffres = (numero ?? '').replaceAll(RegExp(r'[^\d]'), '');
  final texte = message == null ? '' : '?text=${Uri.encodeComponent(message)}';
  return ouvrirLien(context, 'https://wa.me/$chiffres$texte');
}

/// Sélecteur de quantité compact (− n +).
class CompteurQuantite extends StatelessWidget {
  final int valeur;
  final ValueChanged<int> onChanged;
  final int max;
  const CompteurQuantite({super.key, required this.valeur, required this.onChanged, this.max = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: valeur > 0 ? AppColor.kSecondary.withValues(alpha: 0.25) : AppColor.kBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: valeur > 0 ? () => onChanged(valeur - 1) : null,
          ),
          Text('$valeur', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: valeur < max ? () => onChanged(valeur + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Champ de saisie standard des formulaires d'expédition.
class ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icone;
  final TextInputType? clavier;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  /// Longueur maximale acceptée par l'API : la saisie s'arrête à cette limite.
  final int? maxLength;
  const ChampTexte({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icone,
    this.clavier,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: clavier,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        inputFormatters: maxLength == null ? null : [LengthLimitingTextInputFormatter(maxLength)],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icone == null ? null : Icon(icone, size: 20, color: AppColor.kPrimary),
        ),
      ),
    );
  }
}

String? requis(String? v, [String? message]) => v == null || v.trim().isEmpty ? (message ?? tr('Champ requis')) : null;
