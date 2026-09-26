import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/i18n/langue.dart';

/// Photos du colis exigées par la catégorie : une photo de l'enveloppe pour
/// des documents, trois angles pour un colis moyen, au moins une pour un XXL.
///
/// Chaque prise de vue est présentée au client, qui la valide ou recommence ;
/// il peut aussi importer une photo depuis sa galerie.
class PrisePhotos extends StatelessWidget {
  final int minimum;
  final List<String> libellesAngles;
  final List<String?> photos;
  final ValueChanged<List<String?>> onChanged;
  final int maximum;

  const PrisePhotos({
    super.key,
    required this.minimum,
    required this.photos,
    required this.onChanged,
    this.libellesAngles = const [],
    this.maximum = 6,
  });

  int get _nbEmplacements {
    final pris = photos.whereType<String>().length;
    return (minimum > pris ? minimum : pris + 1).clamp(1, maximum);
  }

  Future<void> _prendre(BuildContext context, int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(tr('Prendre une photo')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(tr('Choisir dans la galerie')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;

    while (context.mounted) {
      final fichier = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1800);
      if (fichier == null || !context.mounted) return;
      // Validation de la prise de vue : le client confirme ou recommence
      final valide = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.all(12),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(fichier.path), fit: BoxFit.contain),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Recommencer'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Valider la photo'))),
          ],
        ),
      );
      if (valide == true) {
        final liste = List<String?>.from(photos);
        while (liste.length <= index) {
          liste.add(null);
        }
        liste[index] = fichier.path;
        onChanged(liste);
        return;
      }
      if (valide == null) return;
    }
  }

  void _retirer(int index) {
    final liste = List<String?>.from(photos);
    if (index < liste.length) liste[index] = null;
    onChanged(liste);
  }

  @override
  Widget build(BuildContext context) {
    final prises = photos.whereType<String>().length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        minimum > 1
            ? tr('Prenez $minimum photos de votre colis sous des angles différents ($prises/$minimum).')
            : tr('Ajoutez au moins une photo ($prises/$minimum).'),
        style: texteDiscret(12),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(_nbEmplacements, (i) {
          final chemin = i < photos.length ? photos[i] : null;
          final libelle = i < libellesAngles.length ? libellesAngles[i] : tr('Photo ${i + 1}');
          return GestureDetector(
            onTap: () => _prendre(context, i),
            child: Stack(children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColor.kBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: chemin == null && i < minimum ? AppColor.kSecondary : AppColor.kLine, width: 1.5),
                  image: chemin == null
                      ? null
                      : DecorationImage(image: FileImage(File(chemin)), fit: BoxFit.cover),
                ),
                child: chemin != null
                    ? null
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColor.kPrimary),
                        const SizedBox(height: 4),
                        Text(libelle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600)),
                      ]),
              ),
              if (chemin != null)
                Positioned(
                  right: 2,
                  top: 2,
                  child: InkWell(
                    onTap: () => _retirer(i),
                    child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ]),
          );
        }),
      ),
    ]);
  }
}
