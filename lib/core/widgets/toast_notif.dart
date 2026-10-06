import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../theme/app_color.dart';

void showToast(
  BuildContext context,
  String title,
  String description,
  ToastificationType type,
) {
  final cfg = _toastConfig(type);

  toastification.showCustom(
    context: context,
    alignment: Alignment.topCenter,
    autoCloseDuration: const Duration(milliseconds: 3800),
    animationDuration: const Duration(milliseconds: 320),
    animationBuilder: (ctx, animation, alignment, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    ),
    builder: (ctx, holder) => _ToastCard(
      title: title,
      description: description,
      icon: cfg.icon,
      accent: cfg.accent,
      iconBg: cfg.iconBg,
      holder: holder,
    ),
  );
}

class _ToastConfig {
  final IconData icon;
  final Color accent;
  final Color iconBg;
  const _ToastConfig({
    required this.icon,
    required this.accent,
    required this.iconBg,
  });
}

_ToastConfig _toastConfig(ToastificationType type) {
  switch (type) {
    case ToastificationType.success:
      return const _ToastConfig(
        icon: Icons.check_rounded,
        accent: AppColor.kSucces,
        iconBg: AppColor.kSuccesLight,
      );
    case ToastificationType.error:
      return const _ToastConfig(
        icon: Icons.close_rounded,
        accent: AppColor.kErreur,
        iconBg: AppColor.kErreurLight,
      );
    case ToastificationType.warning:
      return const _ToastConfig(
        icon: Icons.warning_amber_rounded,
        accent: AppColor.kAlerte,
        iconBg: AppColor.kSecondaryLight,
      );
    case ToastificationType.info:
    default:
      return const _ToastConfig(
        icon: Icons.info_outline_rounded,
        accent: AppColor.kPrimary,
        iconBg: AppColor.kPrimaryLight,
      );
  }
}

class _ToastCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color iconBg;
  final ToastificationItem holder;

  const _ToastCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.holder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Barre accent gauche
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(width: 4, color: accent),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Textes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kGrayscaleDark100,
                                height: 1.2,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColor.kGrayscale40,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Bouton fermer
                      GestureDetector(
                        onTap: () => toastification.dismiss(holder),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Barre de progression en bas
                Positioned(
                  left: 4, right: 0, bottom: 0,
                  child: _ProgressBar(
                    duration: const Duration(milliseconds: 3800),
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  const _ProgressBar({required this.duration, required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        height: 2,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 1 - _ctrl.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

