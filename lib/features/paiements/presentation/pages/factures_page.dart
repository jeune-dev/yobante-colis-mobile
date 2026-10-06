import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/document_page.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/paiements_remote_datasource.dart';
import '../../domain/entities/reglement.dart';
import '../bloc/paiements_bloc.dart';
import '../bloc/paiements_event.dart';
import '../bloc/paiements_state.dart';
import '../../../../core/i18n/langue.dart';
import '../../domain/entities/facture_colis.dart';

/// Page autonome (fournit son propre [PaiementsBloc]) — accessible depuis le
/// tiroir latéral, indépendamment des onglets de la coquille principale.
class FacturesPage extends StatelessWidget {
  const FacturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaiementsBloc>(),
      child: const _FacturesView(),
    );
  }
}

class _FacturesView extends StatefulWidget {
  const _FacturesView();

  @override
  State<_FacturesView> createState() => _FacturesViewState();
}

class _FacturesViewState extends State<_FacturesView> {
  static DateFormat get _dateFmt => formatDateCourte();
  bool? _isAuth;

  /// Filtre appliqué par le backend : « impayees » ou un statut de facture.
  String _filtre = 'toutes';

  static Map<String, String> get _filtres => {
        'toutes': tr('Toutes'),
        'impayees': tr('À payer'),
        'payee': tr('Payées'),
        'annulee': tr('Annulées'),
        'remboursee': tr('Remboursées'),
      };

  LoadFactures get _chargement => switch (_filtre) {
        'toutes' => const LoadFactures(),
        'impayees' => const LoadFactures(impayees: true),
        final statut => LoadFactures(statut: statut),
      };

  Widget _barreFiltres() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: _filtres.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _filtre == e.key,
                      onSelected: (_) {
                        setState(() => _filtre = e.key);
                        context.read<PaiementsBloc>().add(_chargement);
                      },
                    ),
                  ))
              .toList(),
        ),
      );

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((auth) {
      if (!mounted) return;
      setState(() => _isAuth = auth);
      if (auth) context.read<PaiementsBloc>().add(const LoadFactures());
    });
  }

  @override
  Widget build(BuildContext context) {
    final connecte = _isAuth == true;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(tr('Mes factures')),
        bottom: connecte
            ? TabBar(tabs: [Tab(text: tr('Factures')), Tab(text: tr('Règlements'))])
            : null,
      ),
      body: _isAuth == null
          ? const Center(child: CircularProgressIndicator())
          : !_isAuth!
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: tr('Aucune facture'),
                  subtitle: tr('Connectez-vous pour consulter vos factures.'),
                  actionLabel: tr('Se connecter'),
                  onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                )
              : TabBarView(children: [
                  Column(children: [
                    const _BandeauEncours(),
                    _barreFiltres(),
                    Expanded(child: BlocBuilder<PaiementsBloc, PaiementsState>(
        builder: (context, state) {
          if (state is PaiementsLoading) return const ShimmerList();
          if (state is PaiementsFailure) return Center(child: Text(state.message));
          if (state is FacturesLoaded) {
            if (state.factures.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: tr('Aucune facture'),
                subtitle: _filtre == 'toutes'
                    ? tr('Vos factures apparaîtront ici après création d\'un colis.')
                    : tr('Aucune facture dans cette catégorie.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PaiementsBloc>().add(_chargement),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.factures.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final f = state.factures[i];
                  final (label, color) = _statutInfo(f.statut);
                  return _CarteFacture(
                    facture: f,
                    statut: label,
                    couleurStatut: color,
                    dateEmission: _formatDate(f.dateEmission),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      )),
                  ]),
                  const _ReglementsView(),
                ]),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return _dateFmt.format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  static (String, Color) _statutInfo(String s) => switch (s) {
    'payee'               => (tr('Payée'), AppColor.kSucces),
    'partiellement_payee' => (tr('Partiellement payée'), AppColor.kInfo),
    'annulee'             => (tr('Annulée'), AppColor.kErreur),
    'remboursee'          => (tr('Remboursée'), Colors.grey),
    _                     => (tr('À payer'), AppColor.kAlerte),
  };
}

/// Sommes restant dues, toutes devises confondues (`GET /client/paiements/encours`).
/// Carte d'une facture : référence et statut, total TTC mis en avant, détail du
/// calcul dans un encadré, puis les actions (voir le document, payer).
class _CarteFacture extends StatelessWidget {
  final FactureColis facture;
  final String statut;
  final Color couleurStatut;
  final String dateEmission;
  const _CarteFacture({
    required this.facture,
    required this.statut,
    required this.couleurStatut,
    required this.dateEmission,
  });

  @override
  Widget build(BuildContext context) {
    final f = facture;
    String m(double v) => formaterMontant(v, f.devise);
    final lignes = <(String, String, Color?)>[
      (tr('Transport'), m(f.montantTransport), null),
      if (f.montantSurcharges > 0) (tr('Surcharges'), m(f.montantSurcharges), null),
      if (f.montantAssurance > 0) (tr('Assurance'), m(f.montantAssurance), null),
      if (f.remise > 0) (tr('Remise'), '-${m(f.remise)}', AppColor.kSucces),
      if (f.montantHt > 0) (tr('Total HT'), m(f.montantHt), null),
      if (f.montantTva > 0) (tr('TVA'), m(f.montantTva), null),
      if (f.montantDroitsDouane > 0) (tr('Droits de douane'), m(f.montantDroitsDouane), null),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_outlined, size: 20, color: AppColor.kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [if (f.colisReference != null) tr('Colis ${f.colisReference}'), tr('Émise le $dateEmission')].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: couleurStatut.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(statut,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleurStatut)),
            ),
          ]),
          const SizedBox(height: 16),
          // Total mis en avant, reste à payer à côté
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Total TTC'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                Text(m(f.montantTotal),
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
              ]),
            ),
            if (f.montantPaye > 0 && f.soldeDu > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColor.kSecondaryLight, borderRadius: BorderRadius.circular(10)),
                child: Text(tr('Reste ${m(f.soldeDu)}'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kAlerte)),
              ),
          ]),
          const SizedBox(height: 12),
          // Détail du calcul
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              for (final (libelle, valeur, couleur) in lignes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                      child: Text(libelle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                    ),
                    Text(valeur,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600, color: couleur ?? AppColor.kGrayscaleDark100)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DocumentPage(
                    titre: tr('Facture ${f.reference}'),
                    chemin: Env.clientFactureDocument(f.id),
                    nomFichier: 'facture-${f.reference}.html',
                  ),
                )),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(tr('Voir')),
              ),
            ),
            if (f.lienPaiement != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ouvrirLien(context, f.lienPaiement),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(tr('Payer')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColor.kSecondary,
                    foregroundColor: AppColor.kPrimary,
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _BandeauEncours extends StatefulWidget {
  const _BandeauEncours();

  @override
  State<_BandeauEncours> createState() => _BandeauEncoursState();
}

class _BandeauEncoursState extends State<_BandeauEncours> {
  Encours? _encours;

  @override
  void initState() {
    super.initState();
    sl<PaiementsRemoteDataSource>().getEncours().then((e) {
      if (mounted) setState(() => _encours = e);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final e = _encours;
    if (e == null || e.nbFacturesImpayees == 0) return const SizedBox.shrink();
    final montants = e.parDevise.entries.map((m) => formaterMontant(m.value, m.key)).join(' + ');
    final echues = e.nbFacturesEchues > 0 ? tr(', dont ${e.nbFacturesEchues} échue(s)') : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Bandeau(
        icone: Icons.account_balance_wallet_outlined,
        titre: tr('Reste à payer : $montants'),
        message: tr('${e.nbFacturesImpayees} facture(s) en attente de règlement$echues.'),
        couleur: e.nbFacturesEchues > 0 ? AppColor.kErreur : AppColor.kAlerte,
      ),
    );
  }
}

/// Historique des règlements et moyens de paiement acceptés.
class _ReglementsView extends StatefulWidget {
  const _ReglementsView();

  @override
  State<_ReglementsView> createState() => _ReglementsViewState();
}

class _ReglementsViewState extends State<_ReglementsView> {
  final _source = sl<PaiementsRemoteDataSource>();
  List<Reglement>? _reglements;
  Map<String, List<String>> _methodes = const {};
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final reglements = await _source.getReglements();
      final methodes = await _source.getMethodes().catchError((_) => <String, List<String>>{});
      if (!mounted) return;
      setState(() {
        _reglements = reglements;
        _methodes = methodes;
        _erreur = null;
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  static String _pays(String code) => switch (code) {
        'FR' => tr('Depuis la France'),
        'SN' => tr('Depuis le Sénégal'),
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    if (_erreur != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: tr('Erreur'),
        subtitle: _erreur!,
        actionLabel: tr('Réessayer'),
        onAction: _charger,
      );
    }
    final liste = _reglements;
    if (liste == null) return const ShimmerList();
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (liste.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(tr('Aucun règlement enregistré pour le moment.'),
                textAlign: TextAlign.center, style: texteDiscret(13)),
          ),
        for (final r in liste)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.payments_outlined, color: AppColor.kPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(formaterMontant(r.montant, r.devise),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  Text([r.methodeLibelle, ?r.factureReference].join(' · '), style: texteDiscret()),
                  Text(formaterDate(r.date.toIso8601String(), avecHeure: true), style: texteDiscret(11)),
                ]),
              ),
              Text(r.statutLibelle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: switch (r.statut) {
                        'succes' => AppColor.kSucces,
                        'echoue' => AppColor.kErreur,
                        _ => AppColor.kGrayscale40,
                      })),
            ]),
          ),
        if (_methodes.isNotEmpty) ...[
          const SizedBox(height: 16),
          CarteSection(titre: tr('Moyens de paiement acceptés'), icone: Icons.credit_card, children: [
            for (final pays in _methodes.entries)
              LigneInfo(_pays(pays.key), pays.value.map((m) => kLibellesMethodePaiement[m] ?? m).join(', ')),
          ]),
        ],
      ]),
    );
  }
}
