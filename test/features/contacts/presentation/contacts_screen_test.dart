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
  testWidgets('displays the empty contacts state', (tester) async {
    final repository = InMemoryContactRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_contactsApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('No contacts yet.'), findsOneWidget);
    expect(
      find.text(
        'Customers, sellers, and other business contacts will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'displays contacts, relationship totals, and alphabetical order',
    (tester) async {
      const jordan = Contact(
        id: 'contact-2',
        name: 'Jordan Smith',
        phone: '555-222-2222',
        email: 'jordan@example.com',
      );
      const alex = Contact(
        id: 'contact-1',
        name: 'Alex Johnson',
        phone: '555-111-1111',
        email: 'alex@example.com',
      );
      final repository = InMemoryContactRepository(
        initialContacts: const [jordan, alex],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _contactsApp(
          repository,
          relationships: const {
            'contact-1': ContactRelationship(
              boughtFromUsCount: 2,
              soldToUsCount: 1,
              consignmentCount: 0,
              history: [],
            ),
            'contact-2': ContactRelationship(
              boughtFromUsCount: 0,
              soldToUsCount: 3,
              consignmentCount: 1,
              history: [],
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 of 2 contacts'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.text('Jordan Smith'), findsOneWidget);
      expect(find.text('555-111-1111'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('555-222-2222'), findsOneWidget);
      expect(find.text('jordan@example.com'), findsOneWidget);
      expect(find.text('Bought From Us: 2'), findsOneWidget);
      expect(find.text('Sold To Us: 1'), findsOneWidget);
      expect(find.text('Consignments: 0'), findsOneWidget);
      expect(find.text('Bought From Us: 0'), findsOneWidget);
      expect(find.text('Sold To Us: 3'), findsOneWidget);
      expect(find.text('Consignments: 1'), findsOneWidget);

      final alexCard = find.byKey(const ValueKey('contact-1'));
      final jordanCard = find.byKey(const ValueKey('contact-2'));
      expect(alexCard, findsOneWidget);
      expect(jordanCard, findsOneWidget);
      expect(
        tester.getTopLeft(alexCard).dy,
        lessThan(tester.getTopLeft(jordanCard).dy),
      );
    },
  );

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

    expect(find.text('1 of 1 contact'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('TM'), findsOneWidget);
    expect(find.text('No contact information entered.'), findsOneWidget);
    expect(find.text('Bought From Us: 0'), findsOneWidget);
    expect(find.text('Sold To Us: 0'), findsOneWidget);
    expect(find.text('Consignments: 0'), findsOneWidget);
  });

  testWidgets('searches contacts and filters inactive contacts', (
    tester,
  ) async {
    final repository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'active', name: 'Alex Johnson', phone: '555-1111'),
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

    expect(find.byKey(const Key('activeContactBadge')), findsOneWidget);
    expect(find.byKey(const Key('inactiveContactBadge')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('contactSearchField')),
      'jordan@example.com',
    );
    await tester.pump();
    expect(find.text('1 of 2 contacts'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsNothing);

    await tester.enterText(find.byKey(const Key('contactSearchField')), '');
    await tester.tap(find.byKey(const Key('contactStatusFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactive').last);
    await tester.pumpAndSettle();
    expect(find.text('Jordan Smith'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsNothing);
  });

  testWidgets('filters contacts by each relationship condition', (
    tester,
  ) async {
    final repository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'buyer', name: 'Buyer Contact'),
        Contact(id: 'seller', name: 'Seller Contact'),
        Contact(id: 'consignor', name: 'Consignor Contact'),
        Contact(id: 'new', name: 'New Contact'),
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

    Future<void> selectRelationship(String label) async {
      await tester.tap(find.byKey(const Key('contactRelationshipFilter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await selectRelationship('Has bought from us');
    expect(find.text('Buyer Contact'), findsOneWidget);
    expect(find.text('Seller Contact'), findsNothing);
    expect(find.text('Consignor Contact'), findsNothing);
    expect(find.text('New Contact'), findsNothing);

    await selectRelationship('Has sold to us');
    expect(find.text('Buyer Contact'), findsNothing);
    expect(find.text('Seller Contact'), findsOneWidget);
    expect(find.text('Consignor Contact'), findsNothing);
    expect(find.text('New Contact'), findsNothing);

    await selectRelationship('Has consignments');
    expect(find.text('Buyer Contact'), findsNothing);
    expect(find.text('Seller Contact'), findsNothing);
    expect(find.text('Consignor Contact'), findsOneWidget);
    expect(find.text('New Contact'), findsNothing);

    await selectRelationship('Has not bought yet');
    expect(find.text('Buyer Contact'), findsNothing);
    expect(find.text('Seller Contact'), findsOneWidget);
    expect(find.text('Consignor Contact'), findsOneWidget);
    expect(find.text('New Contact'), findsOneWidget);
  });

  testWidgets('tapping a contact opens its detail screen', (tester) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
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

    final contactCard = find.byKey(const ValueKey('contactCard-contact-1'));
    expect(contactCard, findsOneWidget);
    await tester.tap(contactCard);
    await tester.pumpAndSettle();

    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Repeat customer.'), findsOneWidget);
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
