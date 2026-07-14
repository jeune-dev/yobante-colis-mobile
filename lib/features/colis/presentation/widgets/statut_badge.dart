import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _info(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }

  static (String, Color) _info(String s) {
    switch (s) {
      case 'en_attente':    return ('En attente',      Colors.orange);
      case 'en_preparation':return ('En préparation',  Colors.blue);
      case 'en_transit':    return ('En transit',      Colors.indigo);
      case 'arrive':        return ('Arrivé',          Colors.teal);
      case 'recupere':      return ('Récupéré',        Colors.cyan);
      case 'livre':         return ('Livré',           Colors.green);
      case 'annule':        return ('Annulé',          Colors.red);
      default:              return (s,                 Colors.grey);
    }
  }
}
