import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color.dart';
import 'langue.dart';

/// Ouvre le choix de la langue de l'application (français ou anglais).
Future<void> choisirLangue(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('Langue de l\'application'),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
            const SizedBox(height: 8),
            RadioGroup<Langue>(
              groupValue: LangueApp.instance.value,
              onChanged: (l) {
                Navigator.of(ctx).pop();
                if (l != null) LangueApp.instance.changer(l);
              },
              child: Column(children: [
                for (final l in Langue.values)
                  RadioListTile<Langue>(
                    value: l,
                    title: Text(l.libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );

/// Ligne « Langue » réutilisable (écran Compte, menu latéral) : affiche la
/// langue courante et ouvre le sélecteur.
class TuileLangue extends StatelessWidget {
  final bool compacte;
  const TuileLangue({super.key, this.compacte = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Langue>(
      valueListenable: LangueApp.instance,
      builder: (context, langue, _) => ListTile(
        dense: compacte,
        contentPadding: compacte ? EdgeInsets.zero : null,
        leading: Icon(Icons.translate, size: compacte ? 18 : 24),
        title: Text(compacte ? langue.libelle : tr('Langue'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: compacte ? 13 : 14)),
        subtitle: compacte ? null : Text(langue.libelle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => choisirLangue(context),
      ),
    );
  }
}
