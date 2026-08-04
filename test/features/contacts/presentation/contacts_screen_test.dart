import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contacts_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('displays the empty contacts state', (WidgetTester tester) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
      ),
    );

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

  testWidgets('displays contacts in alphabetical order', (
    WidgetTester tester,
  ) async {
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
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 contacts'), findsOneWidget);

    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);

    expect(find.text('555-111-1111'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);

    expect(find.text('555-222-2222'), findsOneWidget);
    expect(find.text('jordan@example.com'), findsOneWidget);

    final alexCard = find.byKey(const ValueKey('contact-1'));

    final jordanCard = find.byKey(const ValueKey('contact-2'));

    expect(alexCard, findsOneWidget);
    expect(jordanCard, findsOneWidget);

    expect(
      tester.getTopLeft(alexCard).dy,
      lessThan(tester.getTopLeft(jordanCard).dy),
    );
  });

  testWidgets('displays initials and missing-contact-information fallback', (
    WidgetTester tester,
  ) async {
    const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');

    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 contact'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('TM'), findsOneWidget);

    expect(find.text('No phone or email entered.'), findsOneWidget);
  });
  testWidgets('tapping a contact opens its detail screen', (
    WidgetTester tester,
  ) async {
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
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
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
