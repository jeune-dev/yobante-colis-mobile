import 'package:yobnate_colis/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryTextFormField extends StatelessWidget {
  const PrimaryTextFormField(
      {super.key,
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
      this.validator});

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
  final FormFieldValidator<String>? validator; // DÃ©claration du validateur

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: AppColor.kBackground,
          border: Border.all(color: AppColor.kLine)),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscaleDark100,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        validator: validator, // Passage du validateur au TextFormField
        decoration: InputDecoration(
          border: InputBorder.none, // La bordure est gÃ©rÃ©e par le Container
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          filled: true,
          fillColor: Colors.transparent, // Le Container gÃ¨re la couleur
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscale40,
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

