import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/application/contact_relationship.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_relationship_providers.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('displays all saved contact details', (
    WidgetTester tester,
  ) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
      address: '100 Main Street',
      notes: 'Repeat customer.',
      photoUrl: 'contact-photo.jpg',
    );

    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => const AsyncData(<String, ContactRelationship>{}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContactDetailScreen(contactId: 'contact-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('TM'), findsOneWidget);
    expect(find.text('Business Contact'), findsOneWidget);
    expect(find.byKey(const Key('activeContactBadge')), findsOneWidget);

    expect(find.text('Contact Information'), findsOneWidget);
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);

    expect(find.text('Additional Information'), findsOneWidget);
    expect(find.text('Repeat customer.'), findsOneWidget);
    expect(find.text('Photo attached'), findsOneWidget);
  });

  testWidgets('displays optional-field fallbacks', (WidgetTester tester) async {
    const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');

    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => const AsyncData(<String, ContactRelationship>{}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContactDetailScreen(contactId: 'contact-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Not specified'), findsNWidgets(4));
    expect(find.text('Not added'), findsOneWidget);
    expect(find.text('No linked transaction history.'), findsOneWidget);
  });

  testWidgets('displays nonfinancial relationship totals and history', (
    WidgetTester tester,
  ) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      isActive: false,
    );
    final relationship = ContactRelationship(
      boughtFromUsCount: 2,
      soldToUsCount: 3,
      consignmentCount: 1,
      history: [
        ContactHistoryEntry(
          type: ContactHistoryType.sale,
          title: 'Bought From Us',
          description: 'BAT-2604-0001 - Test Bat',
          date: DateTime(2026, 4, 15),
          inventoryItemId: 'item-1',
          transactionId: 'sale-1',
        ),
        const ContactHistoryEntry(
          type: ContactHistoryType.trade,
          title: 'Trade-In With Sale',
          description: 'Received: Test Glove; Provided: Test Bat',
          transactionId: 'trade-1',
        ),
      ],
    );
    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => AsyncData({'contact-1': relationship}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContactDetailScreen(contactId: 'contact-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inactiveContactBadge')), findsOneWidget);
    expect(find.text('Relationship Overview'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('boughtFromUsMetric')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('soldToUsMetric')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('consignmentsMetric')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Transaction History'), findsOneWidget);
    expect(find.text('Bought From Us'), findsAtLeastNWidgets(2));
    expect(find.text('BAT-2604-0001 - Test Bat'), findsOneWidget);
    expect(find.text('4/15/2026'), findsOneWidget);
    expect(find.text('Trade-In With Sale'), findsOneWidget);
    expect(find.text('Date not available'), findsOneWidget);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('displays not-found state for unknown contact ID', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(repository),
          contactRelationshipsProvider.overrideWith(
            (ref) => const AsyncData(<String, ContactRelationship>{}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ContactDetailScreen(contactId: 'missing-contact'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Contact not found.'), findsOneWidget);

    expect(
      find.text('The contact may have been removed or is no longer available.'),
      findsOneWidget,
    );
  });
}
