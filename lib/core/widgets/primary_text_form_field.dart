import 'package:yobante_colis/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryTextFormField extends StatelessWidget {
  const PrimaryTextFormField({
    super.key,
    required this.hintText,
    this.keyboardType,
    required this.controller,
    this.width = double.maxFinite,
    this.height = 55,
    this.hintTextColor,
    this.onChanged,
    this.onTapOutside,
    this.prefixIcon,
    this.prefixIconColor,
    this.inputFormatters,
    this.maxLines = 1,
    this.borderRadius,
    this.validator,
  });

  final BorderRadiusGeometry? borderRadius;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Function(PointerDownEvent)? onTapOutside;
  final Function(String)? onChanged;
  final double width, height;
  final TextEditingController controller;
  final Color? hintTextColor, prefixIconColor;
  final TextInputType? keyboardType;
  final int? maxLines;
  final FormFieldValidator<String>? validator; // Déclaration du validateur

  @override
  Widget build(BuildContext context) {
    // Apparence du thème des formulaires (app_theme.dart) : fond clair, contour fin,
    // bleu de la marque au focus. Pas de hauteur fixe : le message d'erreur s'affiche
    // sous le champ au lieu d'être coupé.
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscaleDark100,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: hintTextColor ?? AppColor.kGrayscale40,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: prefixIcon,
          prefixIconColor: prefixIconColor,
        ),
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        onTapOutside: onTapOutside,
      ),
    );
  }
}
