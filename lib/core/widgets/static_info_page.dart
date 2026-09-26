import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color.dart';

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
  const StaticInfoSection({this.titre, required this.corps});
}
