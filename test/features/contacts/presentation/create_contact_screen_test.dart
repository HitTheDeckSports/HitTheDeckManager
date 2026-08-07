import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/create_contact_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('displays the Create Contact form fields', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: CreateContactScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Contact'), findsOneWidget);

    expect(
      find.text('Create a customer, seller, or other business contact.'),
      findsOneWidget,
    );

    expect(find.byKey(const Key('contactNameField')), findsOneWidget);

    expect(find.byKey(const Key('contactPhoneField')), findsOneWidget);

    expect(find.byKey(const Key('contactEmailField')), findsOneWidget);

    expect(find.byKey(const Key('contactAddressField')), findsOneWidget);

    expect(find.byKey(const Key('contactNotesField')), findsOneWidget);

    expect(find.byKey(const Key('contactSubmitButton')), findsOneWidget);

    expect(find.text('Save Contact'), findsOneWidget);
  });

  testWidgets('validates required name and optional email format', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: CreateContactScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('contactEmailField')),
      'invalid-email',
    );

    final submitButton = find.byKey(const Key('contactSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);

    expect(find.text('Enter a valid email address.'), findsOneWidget);

    expect(await repository.getContacts(), isEmpty);
  });

  testWidgets('creates a contact and opens its detail screen', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.createContact,
      routes: [
        GoRoute(
          path: AppRoutes.createContact,
          name: AppRouteNames.createContact,
          builder: (context, state) {
            return const Scaffold(body: CreateContactScreen());
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

    await tester.enterText(
      find.byKey(const Key('contactNameField')),
      'Taylor Morgan',
    );

    await tester.enterText(
      find.byKey(const Key('contactPhoneField')),
      '555-123-4567',
    );

    await tester.enterText(
      find.byKey(const Key('contactEmailField')),
      'taylor@example.com',
    );

    await tester.enterText(
      find.byKey(const Key('contactAddressField')),
      '100 Main Street',
    );

    await tester.enterText(
      find.byKey(const Key('contactNotesField')),
      'Repeat customer.',
    );

    await tester.ensureVisible(find.byKey(const Key('contactSubmitButton')));

    await tester.tap(find.byKey(const Key('contactSubmitButton')));

    await tester.pumpAndSettle();

    final contacts = await repository.getContacts();

    expect(contacts, hasLength(1));

    final savedContact = contacts.single;

    expect(savedContact.id, isNotNull);
    expect(savedContact.name, 'Taylor Morgan');
    expect(savedContact.phone, '555-123-4567');
    expect(savedContact.email, 'taylor@example.com');
    expect(savedContact.address, '100 Main Street');
    expect(savedContact.notes, 'Repeat customer.');

    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Repeat customer.'), findsOneWidget);
  });
}
