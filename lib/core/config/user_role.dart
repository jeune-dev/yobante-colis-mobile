import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../i18n/langue.dart';

enum UserRole { client, admin, superAdmin, unknown }

extension UserRoleX on UserRole {
  static UserRole fromString(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'client':
        return UserRole.client;
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

  String get label {
    switch (this) {
      case UserRole.client:     return tr('Client');
      case UserRole.admin:      return tr('Administrateur');
      case UserRole.superAdmin: return tr('Super Admin');
      case UserRole.unknown:    return tr('Inconnu');
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.client:     return AppColor.kSucces.withValues(alpha: 0.2);
      case UserRole.admin:      return AppColor.kInfo.withValues(alpha: 0.2);
      case UserRole.superAdmin: return AppColor.kInfo.withValues(alpha: 0.2);
      default:                  return Colors.grey.withValues(alpha: 0.15);
    }
  }
}
