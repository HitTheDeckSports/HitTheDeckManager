import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/search/application/universal_search.dart';
import 'package:hit_the_deck_manager/features/search/presentation/universal_search_screen.dart';

void main() {
  const entries = [
    UniversalSearchEntry(
      type: UniversalSearchResultType.inventory,
      id: 'inventory-1',
      title: 'Combat Spec H1',
      subtitle: 'BAT-2608-0001',
      searchText: 'Combat Spec H1 BAT-2608-0001 BBCOR',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.contact,
      id: 'contact-1',
      title: 'John Smith',
      subtitle: 'john@example.com',
      searchText: 'John Smith john@example.com',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.transaction,
      id: 'sale-1',
      title: 'Sale BAT-2608-0001',
      subtitle: 'John Smith',
      searchText: 'sale BAT-2608-0001 John Smith',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.deal,
      id: 'deal-1',
      title: 'Deal',
      subtitle: 'Parent sale sale-1',
      searchText: 'deal sale-1 BAT-2608-0001',
    ),
  ];

  testWidgets('blank search shows guidance', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: UniversalSearchScreen(entriesOverride: entries)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('universalSearchField')), findsOneWidget);
    expect(find.text('Search Hit the Deck Manager'), findsOneWidget);
    expect(find.text('Inventory'), findsNothing);
  });

  testWidgets('search groups matching results by type', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: UniversalSearchScreen(entriesOverride: entries)),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('universalSearchField')),
      'BAT-2608-0001',
    );
    await tester.pumpAndSettle();

    expect(find.text('3 results'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Deals'), findsOneWidget);
    expect(find.text('Contacts'), findsNothing);
  });

  testWidgets('clear search returns to guidance state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: UniversalSearchScreen(entriesOverride: entries)),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('universalSearchField')),
      'Combat',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('universalSearchClearButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('universalSearchClearButton')));
    await tester.pumpAndSettle();

    expect(find.text('Search Hit the Deck Manager'), findsOneWidget);
  });

  testWidgets('inventory result navigates to inventory detail', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.search,
      routes: [
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const Scaffold(
            body: UniversalSearchScreen(entriesOverride: entries),
          ),
        ),
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) => Scaffold(
            body: Text('Inventory ${state.pathParameters['itemId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.enterText(
      find.byKey(const Key('universalSearchField')),
      'Combat',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('universalSearchResult-inventory-inventory-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory inventory-1'), findsOneWidget);
  });

  testWidgets('contact result navigates to contact detail', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.search,
      routes: [
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const Scaffold(
            body: UniversalSearchScreen(entriesOverride: entries),
          ),
        ),
        GoRoute(
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) => Scaffold(
            body: Text('Contact ${state.pathParameters['contactId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.enterText(
      find.byKey(const Key('universalSearchField')),
      'John Smith',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('universalSearchResult-contact-contact-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contact contact-1'), findsOneWidget);
  });
}
