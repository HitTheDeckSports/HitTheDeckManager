import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/application/contact_relationship.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contacts_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_relationship_providers.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('Add Contact returns to the existing Contacts screen', (
    tester,
  ) async {
    final repository = InMemoryContactRepository();
    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.contacts,
      routes: [
        GoRoute(
          path: AppRoutes.contacts,
          name: AppRouteNames.contacts,
          builder: (context, state) => const Scaffold(body: ContactsScreen()),
        ),
        GoRoute(
          path: AppRoutes.createContact,
          name: AppRouteNames.createContact,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Add Contact destination')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => const AsyncData(<String, ContactRelationship>{}),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addContactButton')));
    await tester.pumpAndSettle();
    expect(find.text('Add Contact destination'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('No contacts yet.'), findsOneWidget);
  });

  testWidgets('uses compact prototype layout and empty contacts state', (
    tester,
  ) async {
    final repository = InMemoryContactRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_contactsApp(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addContactButton')), findsOneWidget);
    expect(find.byKey(const Key('contactSearchField')), findsNothing);
    expect(find.text('No contacts yet.'), findsOneWidget);
    expect(
      find.text(
        'Customers, sellers, and other business contacts will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows prototype relationship values and sorts by last interaction',
    (tester) async {
      const older = Contact(
        id: 'contact-2',
        name: 'Jordan Smith',
        phone: '5552222222',
        email: 'jordan@example.com',
      );
      const newer = Contact(
        id: 'contact-1',
        name: 'Alex Johnson',
        phone: '5551111111',
        email: 'alex@example.com',
      );
      final repository = InMemoryContactRepository(
        initialContacts: const [older, newer],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _contactsApp(
          repository,
          relationships: {
            'contact-1': ContactRelationship(
              boughtFromUsCount: 2,
              soldToUsCount: 1,
              consignmentCount: 0,
              boughtFromUsCents: 125000,
              soldToUsCents: 45000,
              history: [
                ContactHistoryEntry(
                  type: ContactHistoryType.sale,
                  title: 'Bought From Us',
                  description: 'BAT-1',
                  date: DateTime(2026, 7, 24),
                ),
              ],
            ),
            'contact-2': ContactRelationship(
              boughtFromUsCount: 1,
              soldToUsCount: 3,
              consignmentCount: 1,
              boughtFromUsCents: 87500,
              soldToUsCents: 60000,
              history: [
                ContactHistoryEntry(
                  type: ContactHistoryType.sale,
                  title: 'Bought From Us',
                  description: 'BAT-2',
                  date: DateTime(2026, 7, 20),
                ),
              ],
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contactSearchField')), findsOneWidget);
      expect(find.byKey(const Key('contactFilterButton')), findsOneWidget);
      expect(find.text('2 Contacts'), findsOneWidget);
      expect(find.text('(555) 111-1111'), findsOneWidget);
      expect(find.text(r'$1,250'), findsOneWidget);
      expect(find.text(r'$450'), findsOneWidget);
      expect(find.text('2 purchases'), findsOneWidget);
      expect(find.text('1 sale'), findsOneWidget);
      expect(find.text('Last transaction: Jul 24, 2026'), findsOneWidget);

      final alexCard = find.byKey(const ValueKey('contact-1'));
      final jordanCard = find.byKey(const ValueKey('contact-2'));
      expect(
        tester.getTopLeft(alexCard).dy,
        lessThan(tester.getTopLeft(jordanCard).dy),
      );
    },
  );

  testWidgets('searches contacts and filters status from one Filter sheet', (
    tester,
  ) async {
    final repository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'active', name: 'Alex Johnson', phone: '5551111111'),
        Contact(
          id: 'inactive',
          name: 'Jordan Smith',
          email: 'jordan@example.com',
          isActive: false,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_contactsApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('contactSearchField')),
      'jordan@example.com',
    );
    await tester.pump();
    expect(find.text('1 of 2 Contacts'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsNothing);

    await tester.tap(find.byKey(const Key('contactSearchClearButton')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('contactFilterButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contactFilterSheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('contactFilterStatusInactive')));
    await tester.tap(find.byKey(const Key('contactFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(find.text('Jordan Smith'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsNothing);
    expect(find.byKey(const Key('contactActiveFilterSummary')), findsOneWidget);
  });

  testWidgets('filters contacts by relationship from the Filter sheet', (
    tester,
  ) async {
    final repository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'buyer', name: 'Buyer Contact'),
        Contact(id: 'seller', name: 'Seller Contact'),
        Contact(id: 'consignor', name: 'Consignor Contact'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _contactsApp(
        repository,
        relationships: const {
          'buyer': ContactRelationship(
            boughtFromUsCount: 1,
            soldToUsCount: 0,
            consignmentCount: 0,
            history: [],
          ),
          'seller': ContactRelationship(
            boughtFromUsCount: 0,
            soldToUsCount: 1,
            consignmentCount: 0,
            history: [],
          ),
          'consignor': ContactRelationship(
            boughtFromUsCount: 0,
            soldToUsCount: 0,
            consignmentCount: 1,
            history: [],
          ),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contactFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contactFilterSoldToUs')));
    await tester.tap(find.byKey(const Key('contactFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(find.text('Buyer Contact'), findsNothing);
    expect(find.text('Seller Contact'), findsOneWidget);
    expect(find.text('Consignor Contact'), findsNothing);
  });

  testWidgets('can sort contacts alphabetically', (tester) async {
    final repository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'z', name: 'Zach Contact'),
        Contact(id: 'a', name: 'Alex Contact'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _contactsApp(
        repository,
        relationships: {
          'z': ContactRelationship(
            boughtFromUsCount: 0,
            soldToUsCount: 0,
            consignmentCount: 0,
            history: [
              ContactHistoryEntry(
                type: ContactHistoryType.sale,
                title: 'Bought From Us',
                description: 'Recent',
                date: DateTime(2026, 9, 17),
              ),
            ],
          ),
          'a': const ContactRelationship.empty(),
        },
      ),
    );
    await tester.pumpAndSettle();

    var alexCard = find.byKey(const ValueKey('a'));
    var zachCard = find.byKey(const ValueKey('z'));
    expect(
      tester.getTopLeft(zachCard).dy,
      lessThan(tester.getTopLeft(alexCard).dy),
    );

    await tester.tap(find.byKey(const Key('contactSortButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (A–Z)').last);
    await tester.pumpAndSettle();

    alexCard = find.byKey(const ValueKey('a'));
    zachCard = find.byKey(const ValueKey('z'));
    expect(
      tester.getTopLeft(alexCard).dy,
      lessThan(tester.getTopLeft(zachCard).dy),
    );
  });

  testWidgets('displays initials and missing-contact-information fallback', (
    tester,
  ) async {
    const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');
    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_contactsApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('TM'), findsOneWidget);
    expect(find.text('No contact information entered.'), findsOneWidget);
    expect(find.text(r'$0'), findsNWidgets(2));
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('tapping a contact opens its detail screen', (tester) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '5551234567',
      email: 'taylor@example.com',
      address: '100 Main Street',
      notes: 'Repeat customer.',
    );
    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );
    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.contacts,
      routes: [
        GoRoute(
          path: AppRoutes.contacts,
          name: AppRouteNames.contacts,
          builder: (context, state) {
            return const Scaffold(body: ContactsScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) {
            return Scaffold(
              body: ContactDetailScreen(
                contactId: state.pathParameters['contactId']!,
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => const AsyncData(<String, ContactRelationship>{}),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('contactSearchField')),
      'Taylor',
    );
    await tester.pumpAndSettle();

    final contactCard = find.byKey(const ValueKey('contactCard-contact-1'));
    expect(contactCard, findsOneWidget);
    await tester.tap(contactCard);
    await tester.pumpAndSettle();

    expect(find.text('Relationship Summary'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('(555) 123-4567'), findsAtLeastNWidgets(1));
    expect(find.text('taylor@example.com'), findsAtLeastNWidgets(1));
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Repeat customer.'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    final restoredSearch = tester.widget<TextField>(
      find.byKey(const Key('contactSearchField')),
    );
    expect(restoredSearch.controller?.text, 'Taylor');
    expect(find.byKey(const ValueKey('contactCard-contact-1')), findsOneWidget);
  });
}

Widget _contactsApp(
  InMemoryContactRepository repository, {
  Map<String, ContactRelationship> relationships = const {},
}) {
  return ProviderScope(
    overrides: [
      contactRepositoryProvider.overrideWithValue(repository),
      contactRelationshipsProvider.overrideWith(
        (ref) => AsyncData(relationships),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
  );
}
