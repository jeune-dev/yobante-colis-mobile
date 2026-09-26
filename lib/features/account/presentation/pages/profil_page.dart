import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/config/user_role.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/account_user.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../injection_container.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../../../../core/i18n/langue.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool? _isAuth;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((auth) {
      if (mounted) setState(() => _isAuth = auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAuth == false) {
      return Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppBar(title: Text(tr('Profil'))),
        body: EmptyState(
          icon: Icons.person_outline,
          title: tr('Vous n\'êtes pas connecté'),
          subtitle: tr('Connectez-vous pour accéder à votre profil.'),
          actionLabel: tr('Se connecter'),
          onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
        ),
      );
    }
    return BlocProvider(
      create: (_) => sl<AccountBloc>()..add(LoadMe()),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatefulWidget {
  const _ProfilView();

  @override
  State<_ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<_ProfilView> {
  void _showEditProfilSheet(BuildContext ctx, AccountUser user) {
    final nomCtrl      = TextEditingController(text: user.nom);
    final prenomCtrl   = TextEditingController(text: user.prenom);
    final telCtrl      = TextEditingController(text: user.telephone);
    final formKey      = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Modifier le profil'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextFormField(
                controller: prenomCtrl,
                decoration: InputDecoration(labelText: tr('Prénom')),
                validator: (v) => v == null || v.trim().length < 2 ? tr('Requis (min 2 car.)') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomCtrl,
                decoration: InputDecoration(labelText: tr('Nom')),
                validator: (v) => v == null || v.trim().length < 2 ? tr('Requis (min 2 car.)') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                decoration: InputDecoration(labelText: tr('Téléphone')),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? tr('Requis') : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(sheetCtx);
                    ctx.read<AccountBloc>().add(ModifierInfoPersonnellesEvent(
                      nom: nomCtrl.text.trim(),
                      prenom: prenomCtrl.text.trim(),
                      telephone: telCtrl.text.trim().replaceAll(RegExp(r'[\s\-.]'), ''),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tr('Enregistrer'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      nomCtrl.dispose();
      prenomCtrl.dispose();
      telCtrl.dispose();
    });
  }

  void _showChangePasswordSheet(BuildContext ctx) {
    final oldCtrl    = TextEditingController();
    final newCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    var obscureOld   = true;
    var obscureNew   = true;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Changer le mot de passe'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: oldCtrl,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: tr('Ancien mot de passe'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setSheetState(() => obscureOld = !obscureOld),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? tr('Requis') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: tr('Nouveau mot de passe'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? tr('Min 6 caractères') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: tr('Confirmer le nouveau mot de passe')),
                  validator: (v) => v != newCtrl.text ? tr('Les mots de passe ne correspondent pas') : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.pop(sheetCtx);
                      ctx.read<AccountBloc>().add(ChangePasswordEvent(
                        oldPassword: oldCtrl.text,
                        newPassword: newCtrl.text,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr('Confirmer'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      oldCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (picked != null && mounted) {
      context.read<AccountBloc>().add(UploadAvatarEvent(picked.path));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Déconnexion'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(tr('Voulez-vous vraiment vous déconnecter ?'), style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Annuler'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.kErreur),
            child: Text(tr('Déconnecter'), style: GoogleFonts.plusJakartaSans(color: Colors.white)),
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
          showToast(context, tr('Succès'), state.message, ToastificationType.success);
        } else if (state is PasswordChanged) {
          // Le backend révoque toutes les sessions après un changement de mot de passe
          showToast(context, tr('Mot de passe modifié'), tr('Reconnectez-vous avec votre nouveau mot de passe.'),
              ToastificationType.success);
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
        } else if (state is AccountError) {
          showToast(context, tr('Erreur'), state.message, ToastificationType.error);
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
              Text(tr('Impossible de charger le profil'), style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<AccountBloc>().add(LoadMe()),
                child: Text(tr('Réessayer')),
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
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
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
                    _sectionCard(
                      tr('Informations personnelles'),
                      Icons.person_outline,
                      [
                        _infoRow(Icons.badge_outlined, tr('Prénom'), user.prenom),
                        _infoRow(Icons.badge_outlined, tr('Nom'), user.nom),
                        _infoRow(Icons.email_outlined, tr('Email'), user.email),
                        _infoRow(Icons.phone_outlined, tr('Téléphone'), user.telephone),
                      ],
                      onEdit: () => _showEditProfilSheet(context, user),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(tr('Compte'), Icons.security_outlined, [
                      _infoRow(Icons.manage_accounts_outlined, tr('Rôle'), role.label),
                      _statusRow(user.isActive),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showChangePasswordSheet(context),
                        icon: const Icon(Icons.lock_outline),
                        label: Text(tr('Changer le mot de passe'),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout, color: AppColor.kErreur),
                        label: Text(tr('Se déconnecter'), style: GoogleFonts.plusJakartaSans(color: AppColor.kErreur, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColor.kErreur),
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
        memCacheWidth: size.toInt(),
        memCacheHeight: size.toInt(),
        placeholder: (_, _) => _defaultAvatar(initials, size),
        errorWidget: (_, _, _) => _defaultAvatar(initials, size),
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

  Widget _sectionCard(String title, IconData icon, List<Widget> children, {VoidCallback? onEdit}) {
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
            Expanded(child: Text(title,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100))),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColor.kPrimary,
                tooltip: tr('Modifier'),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
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
    final color = active ? AppColor.kSucces : AppColor.kAlerte;
    final label = active ? tr('Actif') : tr('Inactif');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(tr('Statut'), style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
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
