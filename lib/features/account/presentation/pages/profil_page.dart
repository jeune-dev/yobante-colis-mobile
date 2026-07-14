import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/config/user_role.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AccountBloc>().state;
    if (state is AccountInitial) {
      context.read<AccountBloc>().add(LoadMe());
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      context.read<AccountBloc>().add(UploadAvatarEvent(picked.path));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vraiment vous déconnecter ?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Déconnecter', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountSuccess) {
          showToast(context, 'Succès', state.message, ToastificationType.success);
        } else if (state is AccountError) {
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      builder: (context, state) {
        if (state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state is AccountLoaded ? state.user
            : state is AccountSuccess ? state.user
            : null;

        if (user == null) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Impossible de charger le profil', style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<AccountBloc>().add(LoadMe()),
                child: const Text('Réessayer'),
              ),
            ]),
          );
        }

        final role = UserRoleX.fromString(user.role);
        final initials = _initials(user.prenom, user.nom);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColor.kPrimary,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => context.read<AccountBloc>().add(LoadMe()),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.kPrimary, AppColor.kPrimary.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            _buildAvatar(user.avatarUrl, initials),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(Icons.camera_alt, size: 14, color: AppColor.kPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      _roleBadge(role),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionCard('Informations personnelles', Icons.person_outline, [
                      _infoRow(Icons.badge_outlined, 'Prénom', user.prenom),
                      _infoRow(Icons.badge_outlined, 'Nom', user.nom),
                      _infoRow(Icons.email_outlined, 'Email', user.email),
                      _infoRow(Icons.phone_outlined, 'Téléphone', user.telephone),
                    ]),
                    const SizedBox(height: 16),
                    _sectionCard('Compte', Icons.security_outlined, [
                      _infoRow(Icons.manage_accounts_outlined, 'Rôle', role.label),
                      _statusRow(user.isActive),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: Text('Se déconnecter', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(String? url, String initials) {
    const size = 80.0;
    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _defaultAvatar(initials, size),
        errorWidget: (_, __, ___) => _defaultAvatar(initials, size),
      );
    } else {
      inner = _defaultAvatar(initials, size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _defaultAvatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withValues(alpha: 0.3),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
    );
  }

  Widget _roleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(role.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    final valid = children.where((w) => w is! SizedBox).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColor.kPrimary),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
          ]),
          const Divider(height: 20),
          ...valid,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ]),
        ),
      ]),
    );
  }

  Widget _statusRow(bool? isActive) {
    final active = isActive ?? true;
    final color = active ? Colors.green : Colors.orange;
    final label = active ? 'Actif' : 'Inactif';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text('Statut', style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  String _initials(String? prenom, String? nom) {
    final p = prenom?.isNotEmpty == true ? prenom![0].toUpperCase() : '';
    final n = nom?.isNotEmpty == true ? nom![0].toUpperCase() : '';
    return '$p$n'.isEmpty ? '?' : '$p$n';
  }
}
