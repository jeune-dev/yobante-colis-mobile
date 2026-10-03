

import 'package:yobante_colis/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
class PrimaryButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final double? elevation;
  final double? fontSize;
  final IconData? iconData;
  final Color textColor;
  final Color bgColor;
  final Widget? child;
  final bool isLoading;
  const PrimaryButton({
    super.key,
    this.onTap,
    required this.text,
    this.width,
    this.height,
    this.elevation = 5,
    this.borderRadius = 12.0,
    this.fontSize,
    this.textColor = AppColor.kWhite,
    this.bgColor = AppColor.kPrimary,
    this.child,
    this.iconData,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final Tween<double> _tween = Tween<double>(begin: 1.0, end: 0.95);
  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              _controller.forward().then((_) => _controller.reverse());
              widget.onTap!();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: ScaleTransition(
          scale: _tween.animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
          ),
          child: Card(
            elevation: widget.elevation ?? 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Container(
              // Hauteur minimale (et non fixe) : le bouton grandit avec la taille du texte
              constraints: BoxConstraints(minHeight: widget.height ?? 55),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              alignment: Alignment.center,
              width: widget.width ?? double.maxFinite,
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColor.kWhite,
                      ),
                    )
                  : widget.child ??
                      Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: widget.fontSize ?? 14,
                          fontWeight: FontWeight.w500,
                          color: widget.textColor,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}


