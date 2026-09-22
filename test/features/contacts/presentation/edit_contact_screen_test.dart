import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/edit_contact_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('loads existing contact values into the edit form', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: EditContactScreen(contactId: 'contact-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Contact'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.byKey(const Key('contactPhotoActionButton')), findsOneWidget);
    expect(find.text('Add Photo'), findsOneWidget);

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('contactNameField')),
    );

    final phoneField = tester.widget<TextFormField>(
      find.byKey(const Key('contactPhoneField')),
    );

    final emailField = tester.widget<TextFormField>(
      find.byKey(const Key('contactEmailField')),
    );

    final addressField = tester.widget<TextFormField>(
      find.byKey(const Key('contactAddressField')),
    );

    final notesField = tester.widget<TextFormField>(
      find.byKey(const Key('contactNotesField')),
    );

    expect(nameField.controller?.text, 'Taylor Morgan');
    expect(phoneField.controller?.text, '555-123-4567');
    expect(emailField.controller?.text, 'taylor@example.com');
    expect(addressField.controller?.text, '100 Main Street');
    expect(notesField.controller?.text, 'Repeat customer.');
  });

  testWidgets('displays not-found state for an unknown contact', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryContactRepository();

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: EditContactScreen(contactId: 'missing-contact')),
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

  testWidgets('Cancel returns from Edit Contact to Contact Detail', (
    WidgetTester tester,
  ) async {
    const contact = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
    );

    final repository = InMemoryContactRepository(
      initialContacts: const [contact],
    );
    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: '/contacts/contact-1/edit',
      routes: [
        GoRoute(
          path: AppRoutes.editContact,
          name: AppRouteNames.editContact,
          builder: (context, state) {
            return Scaffold(
              body: EditContactScreen(
                contactId: state.pathParameters['contactId']!,
              ),
            );
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

    final cancelButton = find.byKey(const Key('contactCancelButton'));
    expect(cancelButton, findsOneWidget);

    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Relationship Summary'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
  });

  testWidgets('updates a contact and returns to its detail screen', (
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
      initialLocation: '/contacts/contact-1/edit',
      routes: [
        GoRoute(
          path: AppRoutes.editContact,
          name: AppRouteNames.editContact,
          builder: (context, state) {
            return Scaffold(
              body: EditContactScreen(
                contactId: state.pathParameters['contactId']!,
              ),
            );
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
      'Taylor A. Morgan',
    );

    await tester.enterText(
      find.byKey(const Key('contactPhoneField')),
      '555-999-8888',
    );

    await tester.enterText(
      find.byKey(const Key('contactEmailField')),
      'taylor.updated@example.com',
    );

    await tester.enterText(
      find.byKey(const Key('contactAddressField')),
      '200 Oak Avenue',
    );

    await tester.enterText(
      find.byKey(const Key('contactNotesField')),
      'Updated customer notes.',
    );

    final submitButton = find.byKey(const Key('contactSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final updatedContact = await repository.getContact('contact-1');

    expect(updatedContact, isNotNull);
    expect(updatedContact?.id, 'contact-1');
    expect(updatedContact?.name, 'Taylor A. Morgan');
    expect(updatedContact?.phone, '555-999-8888');
    expect(updatedContact?.email, 'taylor.updated@example.com');
    expect(updatedContact?.address, '200 Oak Avenue');
    expect(updatedContact?.notes, 'Updated customer notes.');

    expect(find.text('Relationship Summary'), findsOneWidget);
    expect(find.text('Taylor A. Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('(555) 999-8888'), findsAtLeastNWidgets(1));
    expect(find.text('taylor.updated@example.com'), findsAtLeastNWidgets(1));
    expect(find.text('200 Oak Avenue'), findsOneWidget);
    expect(find.text('Updated customer notes.'), findsOneWidget);
  });
}
