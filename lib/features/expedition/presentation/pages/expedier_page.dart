import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../catalogue/presentation/pages/nos_tarifs_page.dart';
import '../../../devis/presentation/pages/devis_page.dart';
import 'assistant_expedition_page.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

/// Onglet « Expédier » : choix de la catégorie, puis parcours d'expédition
/// (connecté) ou simulation de tarif (sans compte).
class ExpedierPage extends StatelessWidget {
  const ExpedierPage({super.key});

  Future<void> _demarrer(BuildContext context, CategorieColis categorie) async {
    final connecte = await isUserAuthenticated();
    if (!context.mounted) return;
    if (!connecte) {
      final choix = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr('Connectez-vous pour expédier'), style: titreSection(17)),
              const SizedBox(height: 6),
              Text(tr('Vous pouvez aussi simuler votre tarif sans compte.'), style: texteDiscret(13)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, 'connexion'), child: Text(tr('Se connecter'))),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.pop(ctx, 'inscription'), child: Text(tr('Créer un compte'))),
              TextButton(onPressed: () => Navigator.pop(ctx, 'devis'), child: Text(tr('Simuler un tarif'))),
            ]),
          ),
        ),
      );
      if (!context.mounted || choix == null) return;
      switch (choix) {
        case 'connexion':
          Navigator.of(context).pushNamed(AppRouter.loginRoute);
        case 'inscription':
          Navigator.of(context).pushNamed(AppRouter.registerRoute);
        default:
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DevisPage(categorie: categorie.code)));
      }
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AssistantExpeditionPage(preremplissage: PreremplissageExpedition(categorie: categorie.code)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        leading: const BoutonMenuOuRetour(),
        title: Text(tr('Expédier')),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(tr('Que souhaitez-vous envoyer ?'), style: titreSection(19)),
        const SizedBox(height: 4),
        Text(tr('Entre la France et le Sénégal, dans les deux sens.'), style: texteDiscret(13)),
        const SizedBox(height: 18),
        ...CategorieColis.toutes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => _demarrer(context, c),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColor.kWhite,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                      child: Icon(c.icone, color: AppColor.kPrimary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c.numero}. ${c.libelle}',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(c.exemples, style: texteDiscret(12)),
                        const SizedBox(height: 8),
                        Text(c.parcours,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
                      ]),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColor.kGrayscale40),
                  ]),
                ),
              ),
            )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevisPage())),
              icon: const Icon(Icons.calculate_outlined),
              label: Text(tr('Simuler')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NosTarifsPage())),
              icon: const Icon(Icons.sell_outlined),
              label: Text(tr('Nos tarifs')),
            ),
          ),
        ]),
      ]),
    );
  }
}
