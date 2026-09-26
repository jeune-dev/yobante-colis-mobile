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
                    Expanded(child: BlocBuilder<PaiementsBloc, PaiementsState>(
        builder: (context, state) {
          if (state is PaiementsLoading) return const ShimmerList();
          if (state is PaiementsFailure) return Center(child: Text(state.message));
          if (state is FacturesLoaded) {
            if (state.factures.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: tr('Aucune facture'),
                subtitle: tr('Vos factures apparaîtront ici après création d\'un colis.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PaiementsBloc>().add(const LoadFactures()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.factures.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final f = state.factures[i];
                  final (label, color) = _statutInfo(f.statut);
                  final dateLabel = _formatDate(f.dateEmission);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.kWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(f.reference,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ]),
                        if (f.colisReference != null) ...[
                          const SizedBox(height: 4),
                          Text(tr('Colis ${f.colisReference}'),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                        ],
                        const SizedBox(height: 8),
                        Text(tr('Transport : ${formaterMontant(f.montantTransport, f.devise)}'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40)),
                        if (f.remise > 0)
                          Text(tr('Remise : -${formaterMontant(f.remise, f.devise)}'),
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kSucces)),
                        const SizedBox(height: 4),
                        Text(tr('Total TTC : ${formaterMontant(f.montantTotal, f.devise)}'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                        if (f.montantPaye > 0 && f.soldeDu > 0)
                          Text(tr('Reste à payer : ${formaterMontant(f.soldeDu, f.devise)}'),
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kAlerte)),
                        const SizedBox(height: 4),
                        Text(tr('Émise le $dateLabel'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => DocumentPage(
                                titre: tr('Facture ${f.reference}'),
                                chemin: Env.clientFactureDocument(f.id),
                                nomFichier: 'facture-${f.reference}.html',
                              ),
                            )),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: Text(tr('Voir la facture')),
                          ),
                        ),
                        if (f.lienPaiement != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => ouvrirLien(context, f.lienPaiement),
                              icon: const Icon(Icons.lock_outline, size: 18),
                              label: Text(tr('Payer')),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.kSecondary, foregroundColor: AppColor.kPrimary),
                            ),
                          ),
                        ],
                      ],
                    ),
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
