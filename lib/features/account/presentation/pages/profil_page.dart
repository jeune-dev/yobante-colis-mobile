import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/i18n/langue.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/validateurs.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/account_user.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

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
      return const Scaffold(
        backgroundColor: AppColor.kBackground,
        body: Center(child: CircularProgressIndicator()),
      );
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
  /// Dernier profil connu : conservé à l'écran pendant un envoi et après une erreur
  /// (sinon un échec de mise à jour de la photo masquait tout le profil).
  AccountUser? _dernierUser;

  // Les feuilles possèdent leurs propres champs (et les libèrent elles-mêmes) :
  // libérer les contrôleurs à la fermeture, pendant l'animation de sortie,
  // provoquait l'écran rouge « _dependents.isEmpty ».
  Future<void> _modifierProfil(AccountUser user) async {
    final modifs = await showModalBottomSheet<ModifierInfoPersonnellesEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FeuilleProfil(user: user),
    );
    if (modifs != null && mounted) context.read<AccountBloc>().add(modifs);
  }

  Future<void> _changerMotDePasse() async {
    final demande = await showModalBottomSheet<ChangePasswordEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FeuilleMotDePasse(),
    );
    if (demande != null && mounted) context.read<AccountBloc>().add(demande);
  }

  Future<void> _changerPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (picked != null && mounted) {
      context.read<AccountBloc>().add(UploadAvatarEvent(picked.path));
    }
  }

  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Déconnexion'), style: titreSection(17)),
        content: Text(tr('Voulez-vous vraiment vous déconnecter ?'), style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annuler'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.kErreur, foregroundColor: Colors.white),
            child: Text(tr('Déconnecter')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountSuccess) {
          if (state.message.isNotEmpty) showToast(context, tr('Succès'), state.message, ToastificationType.success);
        } else if (state is PasswordChanged) {
          // Le backend révoque toutes les sessions après un changement de mot de passe
          if (state.message.isNotEmpty) {
            showToast(context, tr('Mot de passe modifié'), state.message, ToastificationType.success);
          }
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
        } else if (state is AccountError) {
          showToast(context, tr('Erreur'), state.message, ToastificationType.error);
        }
      },
      builder: (context, state) {
        if (state is AccountLoaded) _dernierUser = state.user;
        if (state is AccountSuccess) _dernierUser = state.user;
        final user = _dernierUser;
        final enCours = state is AccountLoading;

        return Scaffold(
          backgroundColor: AppColor.kBackground,
          appBar: AppBar(
            backgroundColor: AppColor.kBackground,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(tr('Mon profil'), style: titreSection(18)),
          ),
          body: user == null
              ? (enCours ? const Center(child: CircularProgressIndicator()) : _erreurChargement(context))
              : RefreshIndicator(
                  onRefresh: () async => context.read<AccountBloc>().add(LoadMe()),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _EnTete(user: user, envoiEnCours: enCours, onPhoto: enCours ? null : _changerPhoto),
                      const SizedBox(height: 20),
                      CarteSection(
                        titre: tr('Informations personnelles'),
                        icone: Icons.person_outline,
                        action: TextButton.icon(
                          onPressed: () => _modifierProfil(user),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(tr('Modifier')),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        children: [
                          _Ligne(Icons.badge_outlined, tr('Prénom'), user.prenom),
                          _Ligne(Icons.badge_outlined, tr('Nom'), user.nom),
                          _Ligne(Icons.mail_outline_rounded, tr('Email'), user.email),
                          _Ligne(Icons.phone_outlined, tr('Téléphone'), user.telephone, dernier: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CarteSection(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: [
                          _Action(
                            icone: Icons.lock_outline_rounded,
                            libelle: tr('Changer le mot de passe'),
                            onTap: _changerMotDePasse,
                          ),
                          const Divider(height: 1, indent: 60),
                          _Action(
                            icone: Icons.logout_rounded,
                            libelle: tr('Se déconnecter'),
                            couleur: AppColor.kErreur,
                            onTap: _deconnecter,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _erreurChargement(BuildContext context) => EmptyState(
        icon: Icons.person_off_outlined,
        title: tr('Impossible de charger le profil'),
        subtitle: tr('Vérifiez votre connexion puis réessayez.'),
        actionLabel: tr('Réessayer'),
        onAction: () => context.read<AccountBloc>().add(LoadMe()),
      );
}

/// Carte d'en-tête : photo (modifiable), nom complet et email.
class _EnTete extends StatelessWidget {
  final AccountUser user;
  final bool envoiEnCours;
  final VoidCallback? onPhoto;
  const _EnTete({required this.user, required this.envoiEnCours, this.onPhoto});

  String get _initiales {
    final p = (user.prenom ?? '').trim();
    final n = (user.nom ?? '').trim();
    final i = '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  @override
  Widget build(BuildContext context) {
    const taille = 92.0;
    final url = user.avatarUrl;
    final initiales = Container(
      color: AppColor.kSecondaryLight,
      alignment: Alignment.center,
      child: Text(
        _initiales,
        style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, color: AppColor.kPrimary),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.kPrimary, Color(0xFF0A55C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: taille,
                  height: taille,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url != null && url.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: (taille * 3).toInt(),
                            placeholder: (_, _) => initiales,
                            errorWidget: (_, _, _) => initiales,
                          )
                        else
                          initiales,
                        if (envoiEnCours)
                          Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColor.kSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.kPrimary, width: 2),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, size: 16, color: AppColor.kPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          if ((user.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            tr('Touchez la photo pour la modifier'),
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'information : pastille d'icône, libellé discret et valeur.
class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String? valeur;
  final bool dernier;
  const _Ligne(this.icone, this.libelle, this.valeur, {this.dernier = false});

  @override
  Widget build(BuildContext context) {
    final v = (valeur ?? '').trim();
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColor.kPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 18, color: AppColor.kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelle, style: texteDiscret(12)),
                const SizedBox(height: 2),
                Text(
                  v.isEmpty ? '—' : v,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrée d'action (mot de passe, déconnexion).
class _Action extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Color couleur;
  final VoidCallback onTap;
  const _Action({required this.icone, required this.libelle, required this.onTap, this.couleur = AppColor.kPrimary});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: couleur.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icone, size: 18, color: couleur),
      ),
      title: Text(
        libelle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: couleur == AppColor.kPrimary ? AppColor.kGrayscaleDark100 : couleur,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: couleur.withValues(alpha: 0.5)),
    );
  }
}

/// Mise en page commune des feuilles : poignée, titre, contenu, bouton.
class _Feuille extends StatelessWidget {
  final String titre;
  final List<Widget> champs;
  final String bouton;
  final VoidCallback onValider;
  const _Feuille({required this.titre, required this.champs, required this.bouton, required this.onValider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(titre, style: titreSection(18)),
            const SizedBox(height: 20),
            ...champs,
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onValider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(bouton, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeuilleProfil extends StatefulWidget {
  final AccountUser user;
  const _FeuilleProfil({required this.user});

  @override
  State<_FeuilleProfil> createState() => _FeuilleProfilState();
}

class _FeuilleProfilState extends State<_FeuilleProfil> {
  final _formKey = GlobalKey<FormState>();
  late final _prenom = TextEditingController(text: widget.user.prenom);
  late final _nom = TextEditingController(text: widget.user.nom);
  late final _telephone = TextEditingController(text: widget.user.telephone);

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      ModifierInfoPersonnellesEvent(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        telephone: _telephone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _Feuille(
        titre: tr('Modifier le profil'),
        bouton: tr('Enregistrer'),
        onValider: _valider,
        champs: [
          TextFormField(
            controller: _prenom,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('Prénom'), prefixIcon: const Icon(Icons.badge_outlined)),
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            validator: texte(requis: true, min: 2, max: 50),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('Nom'), prefixIcon: const Icon(Icons.badge_outlined)),
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            validator: texte(requis: true, min: 2, max: 50),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telephone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: tr('Téléphone'), prefixIcon: const Icon(Icons.phone_outlined)),
            validator: telephone(),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _FeuilleMotDePasse extends StatefulWidget {
  const _FeuilleMotDePasse();

  @override
  State<_FeuilleMotDePasse> createState() => _FeuilleMotDePasseState();
}

class _FeuilleMotDePasseState extends State<_FeuilleMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masquerAncien = true;
  bool _masquerNouveau = true;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(context, ChangePasswordEvent(oldPassword: _ancien.text, newPassword: _nouveau.text));
  }

  Widget _oeil(bool masque, VoidCallback basculer) => IconButton(
        icon: Icon(masque ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        onPressed: basculer,
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _Feuille(
        titre: tr('Changer le mot de passe'),
        bouton: tr('Confirmer'),
        onValider: _valider,
        champs: [
          TextFormField(
            controller: _ancien,
            obscureText: _masquerAncien,
            decoration: InputDecoration(
              labelText: tr('Ancien mot de passe'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _oeil(_masquerAncien, () => setState(() => _masquerAncien = !_masquerAncien)),
            ),
            validator: (v) => v == null || v.isEmpty ? tr('Requis') : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nouveau,
            obscureText: _masquerNouveau,
            decoration: InputDecoration(
              labelText: tr('Nouveau mot de passe'),
              helperText: tr('8 caractères min., une majuscule, un chiffre, un caractère spécial'),
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: _oeil(_masquerNouveau, () => setState(() => _masquerNouveau = !_masquerNouveau)),
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(72)],
            validator: motDePasse,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmation,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('Confirmer le nouveau mot de passe'),
              prefixIcon: const Icon(Icons.check_circle_outline_rounded),
            ),
            validator: (v) => v != _nouveau.text ? tr('Les mots de passe ne correspondent pas') : null,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
