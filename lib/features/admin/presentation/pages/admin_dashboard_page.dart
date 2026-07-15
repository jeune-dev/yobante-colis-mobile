import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../../colis/presentation/widgets/statut_badge.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  List<dynamic> _derniersColis = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<Dio>();
      final statsFuture = dio.get(Env.adminDashStats);
      final colisFuture = dio.get(Env.adminDashDerniersColis, queryParameters: {'limit': 5});
      final statsRes = await statsFuture;
      final colisRes = await colisFuture;
      if (!mounted) return;
      setState(() {
        _stats = statsRes.data['data'] as Map<String, dynamic>?;
        _derniersColis = colisRes.data['data']['colis'] as List? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_stats != null) ...[
                          const _SectionTitle('Vue d\'ensemble'),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                            children: [
                              _StatCard('Total colis', '${_stats?['totalColis'] ?? 0}', Icons.inventory_2_outlined, Colors.blue),
                              _StatCard('Total clients', '${_stats?['totalClients'] ?? 0}', Icons.people_outline, Colors.green),
                              _StatCard('En transit', '${_stats?['colisEnTransit'] ?? 0}', Icons.local_shipping_outlined, Colors.orange),
                              _StatCard('Livrés', '${_stats?['colisLivres'] ?? 0}', Icons.check_circle_outline, Colors.teal),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        const _SectionTitle('Derniers colis'),
                        const SizedBox(height: 12),
                        ..._derniersColis.map((c) {
                          final m = c as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColor.kWhite,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['reference'] as String? ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text('${m['expediteurNom']} → ${m['destinataireNom']}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                                    ],
                                  ),
                                ),
                                StatutBadge(statut: m['statut'] as String? ?? ''),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700));
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
        ],
      ),
    );
  }
}
