import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';

void main() {
  test('Owner has financial and administrative permissions', () {
    final permissions = AppPermissions.forRole(AuthorizedUserRole.owner);

    expect(permissions.canViewFinancialData, isTrue);
    expect(permissions.canAccessReports, isTrue);
    expect(permissions.canDisposeInventory, isTrue);
    expect(permissions.canManageUsers, isTrue);
    expect(permissions.canManageBusinessSettings, isTrue);
  });

  test('Admin has financial and administrative permissions', () {
    final permissions = AppPermissions.forRole(AuthorizedUserRole.admin);

    expect(permissions.canViewFinancialData, isTrue);
    expect(permissions.canAccessReports, isTrue);
    expect(permissions.canDisposeInventory, isTrue);
    expect(permissions.canManageUsers, isTrue);
    expect(permissions.canManageBusinessSettings, isTrue);
  });

  test('ordinary User is restricted from financial and admin permissions', () {
    final permissions = AppPermissions.forRole(AuthorizedUserRole.user);

    expect(permissions.canViewFinancialData, isFalse);
    expect(permissions.canAccessReports, isFalse);
    expect(permissions.canDisposeInventory, isFalse);
    expect(permissions.canManageUsers, isFalse);
    expect(permissions.canManageBusinessSettings, isFalse);
  });
}
