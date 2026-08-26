import 'authorized_user.dart';

class AppPermissions {
  const AppPermissions({
    required this.canViewFinancialData,
    required this.canAccessReports,
    required this.canDisposeInventory,
    required this.canManageUsers,
    required this.canManageBusinessSettings,
  });

  const AppPermissions.none()
    : canViewFinancialData = false,
      canAccessReports = false,
      canDisposeInventory = false,
      canManageUsers = false,
      canManageBusinessSettings = false;

  const AppPermissions.ownerOrAdmin()
    : canViewFinancialData = true,
      canAccessReports = true,
      canDisposeInventory = true,
      canManageUsers = true,
      canManageBusinessSettings = true;

  final bool canViewFinancialData;
  final bool canAccessReports;
  final bool canDisposeInventory;
  final bool canManageUsers;
  final bool canManageBusinessSettings;

  factory AppPermissions.forRole(AuthorizedUserRole role) {
    return switch (role) {
      AuthorizedUserRole.owner => const AppPermissions.ownerOrAdmin(),
      AuthorizedUserRole.admin => const AppPermissions.ownerOrAdmin(),
    };
  }
}
