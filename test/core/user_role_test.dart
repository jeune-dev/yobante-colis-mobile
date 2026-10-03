import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/core/config/user_role.dart';

void main() {
  group('UserRoleX.fromString', () {
    test('parse "client"', () {
      expect(UserRoleX.fromString('client'), UserRole.client);
    });

    test('parse "admin"', () {
      expect(UserRoleX.fromString('admin'), UserRole.admin);
    });

    test('parse "super_admin"', () {
      expect(UserRoleX.fromString('super_admin'), UserRole.superAdmin);
    });

    test('valeur inconnue retourne unknown', () {
      expect(UserRoleX.fromString('xyz'), UserRole.unknown);
    });

    test('null retourne unknown', () {
      expect(UserRoleX.fromString(null), UserRole.unknown);
    });
  });

  group('UserRole.isAdmin', () {
    test('true pour admin', () {
      expect(UserRoleX.fromString('admin').isAdmin, true);
    });

    test('true pour super_admin', () {
      expect(UserRoleX.fromString('super_admin').isAdmin, true);
    });

    test('false pour client', () {
      expect(UserRoleX.fromString('client').isAdmin, false);
    });

    test('false pour unknown', () {
      expect(UserRole.unknown.isAdmin, false);
    });
  });
}
