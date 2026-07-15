import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../injection_container.dart';
import 'package:toastification/toastification.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'limit': 50};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await sl<Dio>().get(Env.adminUsers, queryParameters: params);
      if (!mounted) return;
      setState(() { _users = res.data['data']['utilisateurs'] as List? ?? []; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () { _searchCtrl.clear(); _load(); },
                ),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => _load(search: v));
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const ShimmerList()
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = _users[i] as Map<String, dynamic>;
                            final isActive = u['isActive'] as bool? ?? true;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColor.kWhite,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  backgroundImage: u['avatarUrl'] != null
                                      ? CachedNetworkImageProvider(u['avatarUrl'] as String)
                                      : null,
                                  child: u['avatarUrl'] == null ? Text(((u['prenom'] as String? ?? 'U')[0]).toUpperCase()) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${u['prenom']} ${u['nom']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  Text(u['email'] as String? ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                                  Text(u['telephone'] as String? ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                ])),
                                Switch(
                                  value: isActive,
                                  onChanged: (v) => _toggleActive(context, u['id'] as String, v),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(BuildContext ctx, String id, bool activate) async {
    try {
      final url = activate ? Env.adminUserActiver(id) : Env.adminUserDesact(id);
      await sl<Dio>().patch(url);
      if (ctx.mounted) showToast(ctx, 'Succès', activate ? 'Compte activé.' : 'Compte désactivé.', ToastificationType.success);
      _load();
    } catch (e) {
      if (ctx.mounted) showToast(ctx, 'Erreur', e.toString(), ToastificationType.error);
    }
  }
}
