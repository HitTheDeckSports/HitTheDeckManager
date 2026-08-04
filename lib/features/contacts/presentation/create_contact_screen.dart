import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import 'contact_form_screen.dart';
import 'forms/contact_form_controller.dart';

class CreateContactScreen extends ConsumerStatefulWidget {
  const CreateContactScreen({super.key});

  @override
  ConsumerState<CreateContactScreen> createState() {
    return _CreateContactScreenState();
  }
}

class _CreateContactScreenState extends ConsumerState<CreateContactScreen> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(contactFormControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContactFormScreen(
      title: 'Add Contact',
      subtitle: 'Create a customer, seller, or other business contact.',
      submitLabel: 'Save Contact',
      onSaved: (contact) {
        final contactId = contact.id;

        if (contactId == null || contactId.isEmpty) {
          return;
        }

        context.goNamed(
          AppRouteNames.contactDetail,
          pathParameters: {'contactId': contactId},
        );
      },
    );
  }
}
