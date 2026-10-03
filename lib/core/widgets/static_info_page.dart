import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color.dart';
import 'ui_kit.dart';

/// Page d'information statique générique (mentions légales, support,
/// sensibilisation à la fraude...), accessible depuis le tiroir latéral.
class StaticInfoPage extends StatelessWidget {
  final String title;
  final List<StaticInfoSection> sections;
  const StaticInfoPage({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final s in sections) ...[
            if (s.titre != null) ...[
              Text(s.titre!,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColor.kPrimary)),
              const SizedBox(height: 8),
            ],
            Text(s.corps,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.6, color: AppColor.kGrayscaleDark100)),
            for (final l in s.liens)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () => ouvrirLien(context, l.url),
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    // Zone tactile d'au moins 44 px de haut.
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(children: [
                      Icon(l.icone, size: 18, color: AppColor.kPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.libelle,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kPrimary,
                                decoration: TextDecoration.underline)),
                      ),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class StaticInfoSection {
  final String? titre;
  final String corps;
  /// Liens cliquables affichés sous le texte (page web, e-mail, téléphone…).
  final List<LienInfo> liens;
  const StaticInfoSection({this.titre, required this.corps, this.liens = const []});
}

class LienInfo {
  final String libelle;
  final String url;
  final IconData icone;
  const LienInfo(this.libelle, this.url, {this.icone = Icons.open_in_new_rounded});
}
