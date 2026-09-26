import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/espace_client_remote_datasource.dart';
import '../../../../core/i18n/langue.dart';

/// Programme de parrainage : code à partager, crédit acquis, filleuls.
class ParrainagePage extends StatefulWidget {
  const ParrainagePage({super.key});

  @override
  State<ParrainagePage> createState() => _ParrainagePageState();
}

class _ParrainagePageState extends State<ParrainagePage> {
  late Future<Parrainage> _parrainage;

  @override
  void initState() {
    super.initState();
    _parrainage = sl<EspaceClientRemoteDataSource>().getParrainage();
  }

  String _messagePartage(Parrainage p) =>
      tr('Envoie tes colis entre la France et le Sénégal avec Yobante ! Inscris-toi avec mon code ${p.code} '
      'et profite de ${p.remiseFilleulPourcent.toStringAsFixed(0)} % de réduction sur ton premier envoi.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Parrainage'))),
      body: FutureBuilder<Parrainage>(
        future: _parrainage,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final message = snap.error is ServerException ? (snap.error as ServerException).message : '${snap.error}';
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message)));
          }
          final p = snap.data!;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.card_giftcard, color: AppColor.kSecondary, size: 40),
                const SizedBox(height: 10),
                Text(tr('Parrainez vos proches'),
                    style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  tr('Ils gagnent ${p.remiseFilleulPourcent.toStringAsFixed(0)} % sur leur premier envoi, '
                  'vous gagnez ${formaterMontant(p.gainParFilleulEur, 'EUR')} de crédit.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: p.code ?? ''));
                    showToast(context, tr('Copié'), tr('Code de parrainage copié.'), ToastificationType.success);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p.code ?? '—',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 3, color: AppColor.kPrimary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy, color: AppColor.kPrimary, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ouvrirWhatsapp(context, message: _messagePartage(p)),
                  icon: const Icon(Icons.share, color: AppColor.kWhite),
                  label: Text(tr('Partager sur WhatsApp'), style: TextStyle(color: AppColor.kWhite)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            CarteSection(titre: tr('Mon crédit'), icone: Icons.account_balance_wallet_outlined, children: [
              LigneInfo(tr('Disponible'), formaterMontant(p.creditDisponibleEur, 'EUR'), fort: true),
              Text(tr('Votre crédit est déduit automatiquement de vos prochaines expéditions.'), style: texteDiscret()),
            ]),
            if (p.bonusBienvenueDisponible) ...[
              const SizedBox(height: 16),
              Bandeau(
                icone: Icons.celebration_outlined,
                titre: tr('Bonus de bienvenue'),
                message: tr('${p.remiseFilleulPourcent.toStringAsFixed(0)} % de réduction sur votre premier envoi.'),
                couleur: AppColor.kSucces,
              ),
            ],
            const SizedBox(height: 16),
            CarteSection(
              titre: tr('Mes filleuls (${p.filleuls.length})'),
              icone: Icons.group_outlined,
              children: p.filleuls.isEmpty
                  ? [Text(tr('Partagez votre code pour parrainer vos premiers proches.'), style: texteDiscret())]
                  : p.filleuls
                      .map((f) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(f.prenom),
                            subtitle: Text(tr('Inscrit le ${formaterDate(f.inscritLe)}')),
                            trailing: Icon(f.premiereExpedition ? Icons.check_circle : Icons.hourglass_empty,
                                color: f.premiereExpedition ? AppColor.kSucces : AppColor.kGrayscale40),
                          ))
                      .toList(),
            ),
          ]);
        },
      ),
    );
  }
}
