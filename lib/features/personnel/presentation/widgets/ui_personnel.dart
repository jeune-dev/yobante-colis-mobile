import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/user_role.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../account/domain/repositories/account_repository.dart';

/// Composants visuels de l'espace du personnel, dans le langage de l'espace
/// client : en-tête jaune arrondi, cartes blanches à ombre douce, pictogrammes
/// sur tuile bleu clair, actions principales dans une barre fixe en bas.

TextStyle _jakarta(double taille, {FontWeight poids = FontWeight.w600, Color couleur = AppColor.kGrayscaleDark100}) =>
    GoogleFonts.plusJakartaSans(fontSize: taille, fontWeight: poids, color: couleur);

/// Ombre des cartes, identique à celle des cartes d'envoi du client.
List<BoxShadow> get ombreCarte =>
    [BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))];

/// Prénom du compte connecté, chargé une fois pour toute la session.
final ValueNotifier<String?> _prenom = ValueNotifier(null);
Future<void> _chargerPrenom() async {
  if (_prenom.value != null) return;
  final res = await sl<AccountRepository>().getMe();
  res.fold((_) {}, (u) => _prenom.value = (u.prenom?.trim().isNotEmpty ?? false) ? u.prenom!.trim() : u.fullName);
}

/// Indicateur de l'en-tête (« 3 passages aujourd'hui ») ; touché, il applique le filtre.
class Indicateur {
  final String valeur;
  final String libelle;
  final IconData icone;
  final VoidCallback? onTap;
  final bool actif;
  const Indicateur(this.valeur, this.libelle, this.icone, {this.onTap, this.actif = false});
}

/// En-tête jaune de l'onglet principal : salutation, rôle et date, indicateurs du jour.
class EnteteEspace extends StatefulWidget {
  final UserRole role;
  final String titre;
  final List<Indicateur> indicateurs;
  const EnteteEspace({super.key, required this.role, required this.titre, this.indicateurs = const []});

  @override
  State<EnteteEspace> createState() => _EnteteEspaceState();
}

class _EnteteEspaceState extends State<EnteteEspace> {
  @override
  void initState() {
    super.initState();
    _chargerPrenom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        color: AppColor.kSecondary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ValueListenableBuilder<String?>(
          valueListenable: _prenom,
          builder: (_, prenom, _) => Text(
            prenom == null ? tr('Bonjour') : tr('Bonjour {p}').replaceAll('{p}', prenom),
            style: _jakarta(22, poids: FontWeight.w800, couleur: AppColor.kPrimary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.role.label} · ${formatDate().format(DateTime.now())}',
          style: _jakarta(13, poids: FontWeight.w500, couleur: AppColor.kPrimary.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 14),
        Text(widget.titre, style: _jakarta(15, poids: FontWeight.w700, couleur: AppColor.kPrimary)),
        if (widget.indicateurs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < widget.indicateurs.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _TuileIndicateur(widget.indicateurs[i])),
            ],
          ]),
        ],
      ]),
    );
  }
}

class _TuileIndicateur extends StatelessWidget {
  final Indicateur i;
  const _TuileIndicateur(this.i);

  @override
  Widget build(BuildContext context) {
    final fond = i.actif ? AppColor.kPrimary : AppColor.kWhite;
    final texte = i.actif ? AppColor.kWhite : AppColor.kPrimary;
    return Material(
      color: fond,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: i.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i.icone, size: 20, color: i.actif ? AppColor.kSecondary : AppColor.kPrimary),
            const SizedBox(height: 8),
            Text(i.valeur, style: _jakarta(22, poids: FontWeight.w800, couleur: texte)),
            Text(
              i.libelle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _jakarta(11, poids: FontWeight.w600, couleur: texte.withValues(alpha: i.actif ? 0.85 : 0.7)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Barre d'application de l'espace (onglets et détails) : bleu de la marque,
/// titre et icônes en blanc.
PreferredSizeWidget barreEspace(String titre, {List<Widget> actions = const []}) => AppBar(
      backgroundColor: AppColor.kPrimary,
      foregroundColor: AppColor.kWhite,
      surfaceTintColor: AppColor.kPrimary,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColor.kWhite),
      actionsIconTheme: const IconThemeData(color: AppColor.kWhite),
      // Logo de la marque sur les onglets ; flèche retour sur les écrans de détail
      leading: Builder(
        builder: (context) => (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : const _LogoBarre(),
      ),
      leadingWidth: 56,
      title: Text(titre, style: _jakarta(17, poids: FontWeight.w800, couleur: AppColor.kWhite)),
      actions: actions,
    );

/// Pictogramme Yobante posé directement sur le bleu de la barre : ses parties
/// bleues passent en blanc, le carré jaune garde sa couleur.
class _LogoBarre extends StatelessWidget {
  const _LogoBarre();

  // Chaque canal ne dépend que du rouge d'origine, faible sur le bleu de la
  // marque et fort sur son jaune : bleu → blanc, jaune → jaune.
  static const _bleuEnBlanc = ColorFilter.matrix([
    0, 0, 0, 0, 255, //
    -0.245, 0, 0, 0, 256.25, //
    -0.83, 0, 0, 0, 259.2, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: ColorFiltered(
          colorFilter: _bleuEnBlanc,
          child: Image.asset(
            'assets/images/logo_yobante_icon.png',
            height: 30,
            semanticLabel: 'Yobante Colis',
            errorBuilder: (_, _, _) => const Icon(Icons.local_shipping, color: AppColor.kWhite, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de filtre en pilules, avec le nombre d'éléments de chaque filtre.
class FiltresPilules<T> extends StatelessWidget {
  final Map<T, String> options;
  final Map<T, int>? compteurs;
  final T valeur;
  final ValueChanged<T> onChanged;
  const FiltresPilules({super.key, required this.options, required this.valeur, required this.onChanged, this.compteurs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final o in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pilule(
                libelle: o.value,
                compteur: compteurs?[o.key],
                actif: o.key == valeur,
                onTap: () => onChanged(o.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pilule extends StatelessWidget {
  final String libelle;
  final int? compteur;
  final bool actif;
  final VoidCallback onTap;
  const _Pilule({required this.libelle, required this.actif, required this.onTap, this.compteur});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: actif ? AppColor.kPrimary : AppColor.kWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: actif ? AppColor.kPrimary : AppColor.kLine),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(libelle, style: _jakarta(13, poids: FontWeight.w700, couleur: actif ? AppColor.kWhite : AppColor.kPrimary)),
            if (compteur != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: actif ? AppColor.kSecondary : AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$compteur', style: _jakarta(11, poids: FontWeight.w800, couleur: AppColor.kPrimary)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Carte d'une mission (enlèvement ou colis) dans les listes.
class CarteMission extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final Widget statut;
  final List<(IconData, String)> lignes;
  final Widget? pied;
  final Color accent;
  final VoidCallback onTap;
  const CarteMission({
    super.key,
    required this.icone,
    required this.titre,
    required this.statut,
    required this.onTap,
    this.sousTitre,
    this.lignes = const [],
    this.pied,
    this.accent = AppColor.kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: ombreCarte),
      child: Material(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: accent, width: 4))),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TuileIcone(icone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _jakarta(14, poids: FontWeight.w700).copyWith(letterSpacing: 0.3)),
                    if (sousTitre != null) ...[
                      const SizedBox(height: 2),
                      Text(sousTitre!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _jakarta(12, couleur: AppColor.kPrimary)),
                    ],
                  ]),
                ),
                const SizedBox(width: 8),
                statut,
              ]),
              if (lignes.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final (ic, texte) in lignes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(ic, size: 16, color: AppColor.kGrayscale40),
                      const SizedBox(width: 8),
                      Expanded(child: Text(texte, style: _jakarta(12, poids: FontWeight.w500, couleur: AppColor.kGrayscale40))),
                    ]),
                  ),
              ],
              if (pied != null) ...[
                const Divider(height: 16),
                pied!,
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Pictogramme sur tuile bleu clair (cartes, en-têtes de section).
class TuileIcone extends StatelessWidget {
  final IconData icone;
  final double taille;
  final Color fond;
  final Color couleur;
  const TuileIcone(this.icone, {super.key, this.taille = 40, this.fond = AppColor.kPrimaryLight, this.couleur = AppColor.kPrimary});

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(taille * 0.3)),
        child: Icon(icone, size: taille * 0.5, color: couleur),
      );
}

/// Bouton rond d'action rapide (appeler, WhatsApp, itinéraire).
class ActionRonde extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  final Color couleur;
  const ActionRonde({super.key, required this.icone, required this.libelle, required this.onTap, this.couleur = AppColor.kPrimary});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(height: 4),
          Text(libelle, style: _jakarta(11, couleur: couleur)),
        ]),
      ),
    );
  }
}

/// Appelle un numéro (contact client, destinataire).
void appeler(BuildContext context, String? telephone) {
  if (telephone == null || telephone.trim().isEmpty) return;
  ouvrirLien(context, 'tel:${nettoyerTelephone(telephone)}');
}

/// Ouvre l'itinéraire vers une adresse dans l'application de cartes du téléphone.
void ouvrirItineraire(BuildContext context, String adresse) => ouvrirLien(
      context,
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(adresse)}',
    );

/// Carte de contact : personne, téléphone, adresse, et actions rapides.
class CarteContact extends StatelessWidget {
  final String role;
  final String nom;
  final String? telephone;
  final String? adresse;
  final List<Widget> details;
  const CarteContact({super.key, required this.role, required this.nom, this.telephone, this.adresse, this.details = const []});

  @override
  Widget build(BuildContext context) {
    final tel = telephone == null || telephone!.isEmpty ? null : nettoyerTelephone(telephone!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(18), boxShadow: ombreCarte),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColor.kSecondaryLight,
            child: Text(
              nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase(),
              style: _jakarta(17, poids: FontWeight.w800, couleur: AppColor.kSecondaryDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.toUpperCase(), style: _jakarta(10, poids: FontWeight.w700, couleur: AppColor.kGrayscale40).copyWith(letterSpacing: 0.8)),
              Text(nom, style: _jakarta(16, poids: FontWeight.w700)),
              if (telephone != null) Text(telephone!, style: _jakarta(12, poids: FontWeight.w500, couleur: AppColor.kGrayscale40)),
            ]),
          ),
        ]),
        if (adresse != null && adresse!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.place_outlined, size: 18, color: AppColor.kPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text(adresse!, style: _jakarta(13, poids: FontWeight.w500))),
          ]),
        ],
        ...details,
        if (tel != null || adresse != null) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (tel != null) ActionRonde(icone: Icons.call_outlined, libelle: tr('Appeler'), onTap: () => ouvrirLien(context, 'tel:$tel')),
            if (tel != null)
              ActionRonde(
                icone: Icons.chat_outlined,
                libelle: 'WhatsApp',
                couleur: AppColor.kSucces,
                onTap: () => ouvrirWhatsapp(context, numero: tel),
              ),
            if (adresse != null && adresse!.isNotEmpty)
              ActionRonde(icone: Icons.directions_outlined, libelle: tr('Itinéraire'), onTap: () => ouvrirItineraire(context, adresse!)),
          ]),
        ],
      ]),
    );
  }
}

/// Section blanche à titre avec pictogramme (détails, règlement, historique).
class SectionDetail extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<Widget> children;
  const SectionDetail({super.key, required this.titre, required this.icone, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(18), boxShadow: ombreCarte),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TuileIcone(icone, taille: 32),
          const SizedBox(width: 10),
          Text(titre, style: _jakarta(15, poids: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}

/// Information à pictogramme : libellé discret au-dessus, valeur en gras.
class InfoIcone extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;
  const InfoIcone(this.icone, this.libelle, this.valeur, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 18, color: AppColor.kPrimaryMedium),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(libelle, style: _jakarta(11, poids: FontWeight.w500, couleur: AppColor.kGrayscale40)),
            Text(valeur, style: _jakarta(14, poids: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

/// Bandeau bleu en tête des détails : référence, statut et information clé.
class HeroDetail extends StatelessWidget {
  final String surTitre;
  final String reference;
  final Widget statut;
  final Widget contenu;
  const HeroDetail({super.key, required this.surTitre, required this.reference, required this.statut, required this.contenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(surTitre.toUpperCase(),
                  style: _jakarta(10, poids: FontWeight.w700, couleur: AppColor.kSecondary).copyWith(letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(reference, style: _jakarta(18, poids: FontWeight.w800, couleur: AppColor.kWhite).copyWith(letterSpacing: 0.4)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(20)),
            child: statut,
          ),
        ]),
        const SizedBox(height: 16),
        contenu,
      ]),
    );
  }
}

/// Progression horizontale (étapes franchies en jaune, étape courante cerclée).
class EtapesProgression extends StatelessWidget {
  final List<String> etapes;

  /// Indice de l'étape en cours ; -1 si la mission a échoué ou a été annulée.
  final int courante;
  const EtapesProgression({super.key, required this.etapes, required this.courante});

  @override
  Widget build(BuildContext context) {
    final echec = courante < 0;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < etapes.length; i++) ...[
        Expanded(
          child: Column(children: [
            Row(children: [
              Expanded(child: Container(height: 3, color: i == 0 ? Colors.transparent : _couleurTrait(i, echec))),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: echec ? AppColor.kErreur.withValues(alpha: 0.6) : (i <= courante ? AppColor.kSecondary : AppColor.kPrimaryMedium),
                  border: i == courante ? Border.all(color: AppColor.kWhite, width: 3) : null,
                ),
                child: i < courante && !echec ? const Icon(Icons.check, size: 13, color: AppColor.kPrimary) : null,
              ),
              Expanded(
                child: Container(height: 3, color: i == etapes.length - 1 ? Colors.transparent : _couleurTrait(i + 1, echec)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              etapes[i],
              textAlign: TextAlign.center,
              style: _jakarta(11,
                  poids: i == courante ? FontWeight.w800 : FontWeight.w600,
                  couleur: i <= courante && !echec ? AppColor.kWhite : AppColor.kWhite.withValues(alpha: 0.6)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Color _couleurTrait(int i, bool echec) =>
      echec ? AppColor.kErreur.withValues(alpha: 0.4) : (i <= courante ? AppColor.kSecondary : AppColor.kPrimaryMedium);
}

/// Chronologie verticale du suivi : pastille et trait, dernière étape en tête.
class Chronologie extends StatelessWidget {
  final List<(String titre, String sousTitre, String? note)> etapes;
  const Chronologie({super.key, required this.etapes});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < etapes.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 22,
              child: Column(children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0 ? AppColor.kSecondary : AppColor.kWhite,
                    border: Border.all(color: i == 0 ? AppColor.kSecondaryDark : AppColor.kLine, width: 2),
                  ),
                ),
                if (i < etapes.length - 1) Expanded(child: Container(width: 2, color: AppColor.kLine)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(etapes[i].$1,
                      style: _jakarta(13, poids: i == 0 ? FontWeight.w800 : FontWeight.w600,
                          couleur: i == 0 ? AppColor.kPrimary : AppColor.kGrayscaleDark100)),
                  Text(etapes[i].$2, style: _jakarta(11, poids: FontWeight.w500, couleur: AppColor.kGrayscale40)),
                  if (etapes[i].$3 != null && etapes[i].$3!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(etapes[i].$3!, style: _jakarta(12, poids: FontWeight.w500, couleur: AppColor.kGrayscale40)),
                    ),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Barre d'actions fixe en bas des détails.
class BarreActions extends StatelessWidget {
  final List<Widget> children;
  const BarreActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ]),
      ),
    );
  }
}

/// Style commun des boutons des barres d'action.
ButtonStyle styleBoutonPlein(Color fond, {Color texte = AppColor.kWhite}) => FilledButton.styleFrom(
      backgroundColor: fond,
      foregroundColor: texte,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: _jakarta(14, poids: FontWeight.w700),
    );

ButtonStyle styleBoutonContour(Color couleur) => OutlinedButton.styleFrom(
      foregroundColor: couleur,
      minimumSize: const Size.fromHeight(52),
      side: BorderSide(color: couleur.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: _jakarta(14, poids: FontWeight.w700),
    );

/// Titre de section dans une liste (« Notifications », « Mes missions »).
class TitreListe extends StatelessWidget {
  final String texte;
  const TitreListe(this.texte, {super.key});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text(texte, style: titreSection(16)));
}
