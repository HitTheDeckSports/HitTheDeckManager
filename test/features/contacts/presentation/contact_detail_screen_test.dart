import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
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
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
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
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: ContactDetailScreen(contactId: 'contact-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Not specified'), findsNWidgets(4));
    expect(find.text('Not added'), findsOneWidget);
  });

  testWidgets('displays not-found state for unknown contact ID', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
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
