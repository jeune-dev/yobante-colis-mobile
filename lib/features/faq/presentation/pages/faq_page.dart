import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/static_info_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/i18n/langue.dart';

Map<String, String> get _libellesRubriques => {
  'general': tr('Général'),
  'expedition': tr('Expédier un colis'),
  'tarifs': tr('Tarifs'),
  'paiement': tr('Paiement'),
  'suivi': tr('Suivi'),
  'douane': tr('Douane'),
  'compte': tr('Mon compte'),
};

/// Questions fréquentes publiées par l'administrateur (`GET /public/faq`).
/// Sans réseau ou sans question publiée, le contenu d'aide intégré est affiché.
class FaqPage extends StatefulWidget {
  final List<StaticInfoSection> secours;
  const FaqPage({super.key, this.secours = const []});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  List<({String rubrique, List<({String question, String reponse})> questions})>? _rubriques;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final res = await sl<Dio>().get(Env.publicFaq, options: Options(extra: {'skipAuthInterceptor': true}));
      final liste = (res.data['data']['rubriques'] as List? ?? [])
          .map((r) => (
                rubrique: r['rubrique'] as String? ?? 'general',
                questions: (r['questions'] as List? ?? [])
                    .map((q) => (question: q['question'] as String? ?? '', reponse: q['reponse'] as String? ?? ''))
                    .toList(),
              ))
          .toList();
      if (mounted) setState(() => _rubriques = liste);
    } catch (_) {
      if (mounted) setState(() => _rubriques = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rubriques = _rubriques;
    if (rubriques != null && rubriques.isEmpty) {
      return StaticInfoPage(title: tr('Aide'), sections: widget.secours);
    }
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Aide et questions fréquentes'))),
      body: rubriques == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in rubriques) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(_libellesRubriques[r.rubrique] ?? r.rubrique,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 14, color: AppColor.kPrimary)),
                ),
                Material(
                  color: AppColor.kWhite,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final q in r.questions)
                      ExpansionTile(
                        shape: const Border(),
                        title: Text(q.question,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedAlignment: Alignment.centerLeft,
                        children: [
                          Text(q.reponse, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5)),
                        ],
                      ),
                  ]),
                ),
              ],
            ]),
    );
  }
}
