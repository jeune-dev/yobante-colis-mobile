import 'package:yobnate_colis/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecondaryButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final String? iconPath;
  final Widget? iconWidget;
  final double width;
  final double height;
  final double borderRadius;
  final double? fontSize;
  final Color textColor;
  final Color bgColor;

  const SecondaryButton({
    super.key,
    this.onTap,
    required this.text,
    this.width = double.maxFinite,
    this.height = 55,
    this.iconPath,
    this.iconWidget,
    this.borderRadius = 12.0,
    this.fontSize,
    this.textColor = AppColor.kGrayscaleDark100,
    this.bgColor = AppColor.kWhite,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
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

  Widget? _buildIcon() {
    if (widget.iconWidget != null) {
      return widget.iconWidget;
    } else if (widget.iconPath != null && widget.iconPath!.isNotEmpty) {
      return Image.asset(widget.iconPath!, width: 24, height: 24);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _buildIcon();

    return GestureDetector(
      onTap: widget.onTap == null
          ? null
          : () {
              _controller.forward().then((_) => _controller.reverse());
              widget.onTap!();
            },
      child: ScaleTransition(
        scale: _tween.animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: Container(
          // Hauteur minimale (et non fixe) : le bouton grandit avec la taille du texte
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          constraints: BoxConstraints(minHeight: widget.height),
          alignment: Alignment.center,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: Border.all(color: AppColor.kLine),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.fontSize ?? 14,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor,
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

