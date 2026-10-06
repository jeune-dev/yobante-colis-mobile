import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../i18n/langue.dart';

/// Rôles du backend (`config/roles.js`) : client, personnel de terrain
/// (coursier, agent de point) et administrateurs.
enum UserRole { client, coursier, agentPoint, admin, superAdmin, unknown }

extension UserRoleX on UserRole {
  static UserRole fromString(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'client':
        return UserRole.client;
      case 'coursier':
        return UserRole.coursier;
      case 'agent_point':
        return UserRole.agentPoint;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.unknown;
    }
  }

  bool get isClient     => this == UserRole.client;
  bool get isAdmin      => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isPersonnelTerrain => this == UserRole.coursier || this == UserRole.agentPoint;

  String get label {
    switch (this) {
      case UserRole.client:     return tr('Client');
      case UserRole.coursier:   return tr('Coursier');
      case UserRole.agentPoint: return tr('Agent de point');
      case UserRole.admin:      return tr('Administrateur');
      case UserRole.superAdmin: return tr('Super Admin');
      case UserRole.unknown:    return tr('Inconnu');
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.client:     return AppColor.kSucces.withValues(alpha: 0.2);
      case UserRole.coursier:
      case UserRole.agentPoint: return AppColor.kAlerte.withValues(alpha: 0.2);
      case UserRole.admin:      return AppColor.kInfo.withValues(alpha: 0.2);
      case UserRole.superAdmin: return AppColor.kInfo.withValues(alpha: 0.2);
      default:                  return Colors.grey.withValues(alpha: 0.15);
    }
  }
}
