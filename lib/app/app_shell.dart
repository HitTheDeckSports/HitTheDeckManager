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
                  onDestinationSelected: (index) => _navigateToIndex(
                    context,
                    index,
                    canAccessReports: canAccessReports,
                  ),
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
                onDestinationSelected: (index) => _navigateToIndex(
                  context,
                  index,
                  canAccessReports: canAccessReports,
                ),
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
    final detailId = _inventoryDetailItemId(currentLocation);
    final editId = _inventoryEditItemId(currentLocation);
    final transactionDetailId = _transactionDetailId(currentLocation);
    final isTransactionFamilyDetail = _isTransactionFamilyDetail(
      currentLocation,
    );
    final isBuy = currentLocation == AppRoutes.buyInventory;
    final isSell = currentLocation == AppRoutes.sellInventory;
    final contextual =
        detailId != null ||
        editId != null ||
        transactionDetailId != null ||
        isTransactionFamilyDetail ||
        isBuy ||
        isSell;

    VoidCallback? backAction;
    Key? backKey;
    String? tooltip;

    if (detailId != null) {
      backAction = () =>
          _backOrFallback(context, () => context.go(AppRoutes.inventory));
      backKey = const Key('inventoryDetailHeaderBackButton');
      tooltip = 'Back to Inventory';
    } else if (editId != null) {
      backAction = () => _backOrFallback(
        context,
        () => context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': editId},
        ),
      );
      backKey = const Key('inventoryEditHeaderBackButton');
      tooltip = 'Back to Inventory Item';
    } else if (transactionDetailId != null || isTransactionFamilyDetail) {
      backAction = () =>
          _backOrFallback(context, () => context.go(AppRoutes.transactions));
      backKey = const Key('transactionDetailHeaderBackButton');
      tooltip = 'Back to Transactions';
    } else if (isBuy || isSell) {
      backAction = () =>
          _backOrFallback(context, () => context.go(AppRoutes.inventory));
      backKey = const Key('inventoryWorkflowHeaderBackButton');
      tooltip = 'Back to Inventory';
    }

    return AppBar(
      backgroundColor: AppTheme.navyDark,
      foregroundColor: Colors.white,
      toolbarHeight: 74,
      centerTitle: contextual,
      titleSpacing: contextual ? 0 : 16,
      leadingWidth: contextual ? 64 : null,
      leading: contextual
          ? IconButton(
              key: backKey,
              tooltip: tooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: backAction,
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
      actions: detailId != null
          ? [
              IconButton(
                key: const Key('inventoryDetailHeaderEditButton'),
                tooltip: 'Edit inventory item',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.goNamed(
                  AppRouteNames.inventoryEdit,
                  pathParameters: {'itemId': detailId},
                ),
              ),
              const SizedBox(width: 6),
            ]
          : contextual
          ? const [SizedBox(width: 54)]
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

  void _backOrFallback(BuildContext context, VoidCallback fallback) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    fallback();
  }

  String? _inventoryDetailItemId(String location) {
    final s = Uri.parse(location).pathSegments;
    if (s.length != 2 || s.first != 'inventory') {
      return null;
    }
    const reserved = {'buy', 'sell', 'scan'};
    return reserved.contains(s[1]) ? null : s[1];
  }

  String? _inventoryEditItemId(String location) {
    final s = Uri.parse(location).pathSegments;
    if (s.length != 3 || s.first != 'inventory' || s[2] != 'edit') {
      return null;
    }
    return s[1];
  }

  String? _transactionDetailId(String location) {
    final s = Uri.parse(location).pathSegments;
    if (s.length != 2 || s.first != 'transactions') {
      return null;
    }
    return s[1];
  }

  bool _isTransactionFamilyDetail(String location) {
    final s = Uri.parse(location).pathSegments;
    if (s.length != 2) {
      return false;
    }

    return const {
      'repairs',
      'trades',
      'disposals',
      'consignments',
      'deals',
    }.contains(s.first);
  }

  List<NavigationDestination> _navigationDestinations({
    required bool canAccessReports,
  }) => [
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

  List<NavigationRailDestination> _railDestinations({
    required bool canAccessReports,
  }) => [
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
