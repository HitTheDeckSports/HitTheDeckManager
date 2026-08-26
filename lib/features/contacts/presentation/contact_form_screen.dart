import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../domain/models/contact.dart';
import 'forms/contact_form_controller.dart';
import 'providers/contact_controller.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    this.initialContact,
    this.onSaved,
    super.key,
  });

  final String title;
  final String subtitle;
  final String submitLabel;
  final Contact? initialContact;
  final ValueChanged<Contact>? onSaved;

  @override
  ConsumerState<ContactFormScreen> createState() {
    return _ContactFormScreenState();
  }
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _hasLoadedInitialContact = false;

  @override
  void initState() {
    super.initState();

    final initialContact = widget.initialContact;

    _nameController = TextEditingController(text: initialContact?.name ?? '');

    _phoneController = TextEditingController(text: initialContact?.phone ?? '');

    _emailController = TextEditingController(text: initialContact?.email ?? '');

    _addressController = TextEditingController(
      text: initialContact?.address ?? '',
    );

    _notesController = TextEditingController(text: initialContact?.notes ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final initialContact = widget.initialContact;

    if (_hasLoadedInitialContact || initialContact == null) {
      return;
    }

    _hasLoadedInitialContact = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(contactFormControllerProvider.notifier)
          .loadContact(initialContact);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return null;
    }

    final atIndex = trimmedValue.indexOf('@');
    final lastDotIndex = trimmedValue.lastIndexOf('.');

    final isValid =
        atIndex > 0 &&
        lastDotIndex > atIndex + 1 &&
        lastDotIndex < trimmedValue.length - 1;

    return isValid ? null : 'Enter a valid email address.';
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final formController = ref.read(contactFormControllerProvider.notifier);

    try {
      final savedContact = await formController.submit();

      if (!mounted) {
        return;
      }

      if (savedContact == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save the contact. Review the entered information.',
            ),
          ),
        );

        return;
      }

      widget.onSaved?.call(savedContact);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialContact == null
                ? '${savedContact.name} was added to Contacts.'
                : '${savedContact.name} was updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save contact: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactControllerState = ref.watch(contactControllerProvider);

    final isSaving = contactControllerState.isLoading;

    final formController = ref.read(contactFormControllerProvider.notifier);

    return AppPage(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('contactNameField'),
              controller: _nameController,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter the contact’s name',
              ),
              validator: (value) {
                return AppValidators.requiredText(value, fieldName: 'Name');
              },
              onChanged: formController.setName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('contactPhoneField'),
              controller: _phoneController,
              enabled: !isSaving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter a phone number',
              ),
              onChanged: formController.setPhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('contactEmailField'),
              controller: _emailController,
              enabled: !isSaving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter an email address',
              ),
              validator: _validateEmail,
              onChanged: formController.setEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('contactAddressField'),
              controller: _addressController,
              enabled: !isSaving,
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter a mailing address',
                alignLabelWithHint: true,
              ),
              onChanged: formController.setAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('contactNotesField'),
              controller: _notesController,
              enabled: !isSaving,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter optional contact notes',
                alignLabelWithHint: true,
              ),
              onChanged: formController.setNotes,
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              key: const Key('contactActiveSwitch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Active contact'),
              subtitle: const Text(
                'Inactive contacts remain available in historical records.',
              ),
              value: ref.watch(contactFormControllerProvider).isActive,
              onChanged: isSaving ? null : formController.setIsActive,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('contactSubmitButton'),
              onPressed: isSaving ? null : _submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Saving Contact...' : widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
