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
  testWidgets('displays redesigned contact identity and information', (
    tester,
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

    expect(find.byKey(const Key('contactIdentityCard')), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('TM'), findsOneWidget);
    expect(find.text('Business Contact'), findsOneWidget);
    expect(find.byKey(const Key('activeContactBadge')), findsOneWidget);
    expect(find.byKey(const Key('editContactButton')), findsOneWidget);

    expect(find.text('Relationship Summary'), findsOneWidget);
    expect(find.text('Contact Information'), findsOneWidget);
    expect(find.text('(555) 123-4567'), findsAtLeastNWidgets(1));
    expect(find.text('taylor@example.com'), findsAtLeastNWidgets(1));
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Repeat customer.'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('contact photo opens in a zoomable full-screen viewer', (
    tester,
  ) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      photoUrl: 'https://example.com/contact.jpg',
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

    expect(find.byKey(const Key('contactPhotoTapTarget')), findsOneWidget);
    expect(find.byKey(const Key('contactPhotoViewer')), findsNothing);

    await tester.tap(find.byKey(const Key('contactPhotoTapTarget')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contactPhotoViewer')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const Key('contactPhotoViewerImage')), findsOneWidget);

    await tester.tap(find.byKey(const Key('contactPhotoViewerCloseButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contactPhotoViewer')), findsNothing);
  });

  testWidgets('shows relationship money, counts, and recent activity', (
    tester,
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
      boughtFromUsCents: 125000,
      soldToUsCents: 45000,
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
    expect(find.text(r'$1,250'), findsOneWidget);
    expect(find.text(r'$450'), findsOneWidget);
    expect(find.text('2 purchases'), findsOneWidget);
    expect(find.text('3 items sold'), findsOneWidget);
    expect(find.byKey(const Key('consignmentsMetric')), findsOneWidget);
    expect(find.text('Bought From Us'), findsAtLeastNWidgets(2));
    expect(find.text('BAT-2604-0001 - Test Bat'), findsOneWidget);
    expect(find.text('Apr 15, 2026'), findsAtLeastNWidgets(1));
    expect(find.text('Trade-In With Sale'), findsOneWidget);
    expect(find.text('Date not available'), findsOneWidget);
  });

  testWidgets('displays optional field fallbacks and empty history', (
    tester,
  ) async {
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
    expect(find.text('No linked transaction history.'), findsOneWidget);
  });

  testWidgets('displays not-found state for unknown contact ID', (
    tester,
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
  });
}
