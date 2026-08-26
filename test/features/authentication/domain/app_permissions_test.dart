import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';

void main() {
  test('Version 1.0 exposes only Owner and Admin roles', () {
    expect(AuthorizedUserRole.values, const [
      AuthorizedUserRole.owner,
      AuthorizedUserRole.admin,
    ]);
  });

  test('Owner has full application permissions', () {
    final permissions = AppPermissions.forRole(AuthorizedUserRole.owner);

    expect(permissions.canViewFinancialData, isTrue);
    expect(permissions.canAccessReports, isTrue);
    expect(permissions.canDisposeInventory, isTrue);
    expect(permissions.canManageUsers, isTrue);
    expect(permissions.canManageBusinessSettings, isTrue);
  });

  test('Admin has full application permissions', () {
    final permissions = AppPermissions.forRole(AuthorizedUserRole.admin);

    expect(permissions.canViewFinancialData, isTrue);
    expect(permissions.canAccessReports, isTrue);
    expect(permissions.canDisposeInventory, isTrue);
    expect(permissions.canManageUsers, isTrue);
    expect(permissions.canManageBusinessSettings, isTrue);
  });
}
