import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Contacts',
      subtitle: 'Manage customers, sellers, and other business contacts.',
      child: Center(child: Text('Contacts content will be added here.')),
    );
  }
}
