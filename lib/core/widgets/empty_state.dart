import 'package:flutter/material.dart';
import '../theme/app_color.dart';

/// Widget état vide réutilisable pour toutes les pages liste.
///
/// [scrollable] = true  → enrobe dans un ListView (pour remplacer un ListView vide)
/// [scrollable] = false → Centre le contenu directement (pour Sliver ou Expanded)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? accentColor;
  final bool scrollable;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
    this.accentColor,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    // Bleu de la marque par défaut : bouton, pastille et icône assortis au thème
    final color = accentColor ?? AppColor.kPrimary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: color.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColor.kGrayscale40, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (!scrollable) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(32), child: content),
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: content),
        ),
      ],
    );
  }
}

