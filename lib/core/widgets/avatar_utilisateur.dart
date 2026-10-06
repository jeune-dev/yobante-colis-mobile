import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color.dart';

/// Photo de profil de l'utilisateur, ou ses initiales s'il n'en a pas
/// (« Ali Sow » → « AS »). Utilisé dans le menu latéral et la page Compte.
class AvatarUtilisateur extends StatelessWidget {
  final String? prenom;
  final String? nom;
  final String? photoUrl;
  final double rayon;

  /// Liseré blanc autour de l'avatar (sur un fond coloré).
  final bool bordure;

  const AvatarUtilisateur({super.key, this.prenom, this.nom, this.photoUrl, this.rayon = 24, this.bordure = false});

  /// Initiales du prénom et du nom, en majuscules (au plus deux lettres).
  static String initiales(String? prenom, String? nom) => [
    prenom,
    nom,
  ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim().characters.first).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final photo = (photoUrl ?? '').isNotEmpty ? photoUrl : null;
    final lettres = initiales(prenom, nom);
    final avatar = CircleAvatar(
      radius: rayon,
      backgroundColor: AppColor.kSecondary,
      foregroundImage: photo == null ? null : NetworkImage(photo),
      // Initiales (ou icône) visibles tant que la photo n'est pas chargée, ou si elle échoue
      child: lettres.isEmpty
          ? Icon(Icons.person_rounded, color: AppColor.kPrimary, size: rayon)
          : Text(
              lettres,
              style: GoogleFonts.plusJakartaSans(
                fontSize: rayon * 0.72,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
    );
    if (!bordure) return avatar;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: AppColor.kWhite, shape: BoxShape.circle),
      child: avatar,
    );
  }
}
