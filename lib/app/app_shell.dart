import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/providers/app_permissions_provider.dart';
import '../features/authentication/presentation/providers/authentication_controller.dart';
import 'app_routes.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final permissions = ref.watch(currentAppPermissionsProvider);
    final canAccessReports = permissions.canAccessReports;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 900;

        if (useNavigationRail) {
          return Scaffold(
            appBar: _buildAppBar(context, currentLocation),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex(
                    currentLocation,
                    canAccessReports: canAccessReports,
                  ),
                  onDestinationSelected: (index) {
                    _navigateToIndex(
                      context,
                      index,
                      canAccessReports: canAccessReports,
                    );
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: _BrandMark(compact: true),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: IconButton(
                      key: const Key('globalSignOutRailButton'),
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _signOut(context, ref),
                    ),
                  ),
                  destinations: _railDestinations(
                    canAccessReports: canAccessReports,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, currentLocation),
          body: child,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: Color(0xFFE4E8EE))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x16062A4D),
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: _selectedIndex(
                  currentLocation,
                  canAccessReports: canAccessReports,
                ),
                onDestinationSelected: (index) {
                  _navigateToIndex(
                    context,
                    index,
                    canAccessReports: canAccessReports,
                  );
                },
                destinations: _navigationDestinations(
                  canAccessReports: canAccessReports,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String currentLocation,
  ) {
    final inventoryDetailItemId = _inventoryDetailItemId(currentLocation);
    final isInventoryDetail = inventoryDetailItemId != null;

    return AppBar(
      backgroundColor: AppTheme.navyDark,
      foregroundColor: Colors.white,
      toolbarHeight: 74,
      centerTitle: isInventoryDetail,
      titleSpacing: isInventoryDetail ? 0 : 16,
      leadingWidth: isInventoryDetail ? 64 : null,
      leading: isInventoryDetail
          ? IconButton(
              key: const Key('inventoryDetailHeaderBackButton'),
              tooltip: 'Back to Inventory',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goNamed(AppRouteNames.inventory),
            )
          : null,
      title: const _BrandMark(),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(3),
        child: SizedBox(
          height: 3,
          child: ColoredBox(color: AppTheme.primaryRed),
        ),
      ),
      actions: isInventoryDetail
          ? [
              IconButton(
                key: const Key('inventoryDetailHeaderEditButton'),
                tooltip: 'Edit inventory item',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  context.goNamed(
                    AppRouteNames.inventoryEdit,
                    pathParameters: {'itemId': inventoryDetailItemId},
                  );
                },
              ),
              const SizedBox(width: 6),
            ]
          : [
              IconButton(
                key: const Key('globalSearchHeaderButton'),
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () => context.go(AppRoutes.search),
              ),
              IconButton(
                key: const Key('globalSettingsHeaderButton'),
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go(AppRoutes.settings),
              ),
              const SizedBox(width: 6),
            ],
    );
  }

  String? _inventoryDetailItemId(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length != 2 || segments.first != 'inventory') {
      return null;
    }

    const reserved = {'buy', 'sell', 'scan'};
    final candidate = segments[1];
    return reserved.contains(candidate) ? null : candidate;
  }

  List<NavigationDestination> _navigationDestinations({
    required bool canAccessReports,
  }) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Inventory',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Transactions',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Contacts',
      ),
      if (canAccessReports)
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
    ];
  }

  List<NavigationRailDestination> _railDestinations({
    required bool canAccessReports,
  }) {
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Inventory'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Transactions'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Contacts'),
      ),
      if (canAccessReports)
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Reports'),
        ),
    ];
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authenticationControllerProvider.notifier).signOut();
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    }
  }

  int _selectedIndex(String location, {required bool canAccessReports}) {
    if (location.startsWith(AppRoutes.inventory)) {
      return 1;
    }

    if (location.startsWith(AppRoutes.transactions)) {
      return 2;
    }

    if (location.startsWith(AppRoutes.contacts)) {
      return 3;
    }

    if (canAccessReports && location.startsWith(AppRoutes.reports)) {
      return 4;
    }

    return 0;
  }

  void _navigateToIndex(
    BuildContext context,
    int index, {
    required bool canAccessReports,
  }) {
    final route = switch (index) {
      0 => AppRoutes.dashboard,
      1 => AppRoutes.inventory,
      2 => AppRoutes.transactions,
      3 => AppRoutes.contacts,
      4 when canAccessReports => AppRoutes.reports,
      _ => AppRoutes.dashboard,
    };

    context.go(route);
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Icon(
        Icons.sports_baseball,
        color: AppTheme.primaryRed,
        size: 34,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sports_baseball, color: Colors.white, size: 35),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'HIT THE DECK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'MANAGER',
              style: TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 13,
                height: 1.0,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
