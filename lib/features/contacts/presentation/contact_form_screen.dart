import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/app_validators.dart';
import '../../../shared/media/photo_service_providers.dart';
import '../../../shared/media/photo_source.dart';
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
  final FutureOr<void> Function(Contact)? onSaved;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _hasLoadedInitialContact = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialContact;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _addressController = TextEditingController(text: initial?.address ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = widget.initialContact;
    if (_hasLoadedInitialContact || initial == null) return;

    _hasLoadedInitialContact = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(contactFormControllerProvider.notifier).loadContact(initial);
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
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final at = trimmed.indexOf('@');
    final dot = trimmed.lastIndexOf('.');
    final valid = at > 0 && dot > at + 1 && dot < trimmed.length - 1;
    return valid ? null : 'Enter a valid email address.';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(contactFormControllerProvider.notifier);

    try {
      final saved = await controller.submit();
      if (!mounted) return;

      if (saved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save the contact. Review the entered information.',
            ),
          ),
        );
        return;
      }

      final onSaved = widget.onSaved;
      if (onSaved != null) {
        await onSaved(saved);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialContact == null
                ? '${saved.name} was added to Contacts.'
                : '${saved.name} was updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save contact: $error')));
    }
  }

  void _cancel() {
    final contactId = widget.initialContact?.id?.trim() ?? '';

    if (context.canPop()) {
      context.pop();
      return;
    }

    if (contactId.isNotEmpty) {
      context.goNamed(
        AppRouteNames.contactDetail,
        pathParameters: {'contactId': contactId},
      );
      return;
    }

    context.goNamed(AppRouteNames.contacts);
  }

  Future<void> _chooseContactPhoto() async {
    final contactId = widget.initialContact?.id?.trim() ?? '';
    if (contactId.isEmpty || _isUploadingPhoto) return;

    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contact Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  key: const Key('contactPhotoCameraOption'),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.of(context).pop(PhotoSource.camera),
                ),
                ListTile(
                  key: const Key('contactPhotoGalleryOption'),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose From Gallery'),
                  onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final picker = ref.read(photoPickerServiceProvider);
      final selected = await picker.pickPhoto(source);
      if (selected == null) return;

      final compressor = ref.read(photoCompressionServiceProvider);
      final bytes = await compressor.compressPhoto(selected);

      final storage = ref.read(photoStorageServiceProvider);
      final stored = await storage.uploadContactPhoto(
        contactId: contactId,
        photoId: const Uuid().v4(),
        jpegBytes: bytes,
      );

      if (!mounted) return;

      ref
          .read(contactFormControllerProvider.notifier)
          .setPhotoUrl(stored.downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact photo added. Save changes to keep it.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add contact photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(contactControllerProvider).isLoading;
    final formState = ref.watch(contactFormControllerProvider);
    final formController = ref.read(contactFormControllerProvider.notifier);

    final displayName = _nameController.text.trim().isEmpty
        ? (widget.initialContact?.name ?? 'New Contact')
        : _nameController.text.trim();

    return AppPage(
      title: widget.title,
      subtitle: widget.subtitle,
      compact: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormIdentityCard(
              name: displayName,
              photoUrl: formState.photoUrl,
              isEditing: widget.initialContact != null,
              isUploadingPhoto: _isUploadingPhoto,
              onPhotoPressed: widget.initialContact?.id == null
                  ? null
                  : _chooseContactPhoto,
            ),
            const SizedBox(height: 12),
            _FormSection(
              icon: Icons.person_outline,
              title: 'Contact Information',
              child: Column(
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
                    validator: (value) =>
                        AppValidators.requiredText(value, fieldName: 'Name'),
                    onChanged: (value) {
                      formController.setName(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('contactPhoneField'),
                    controller: _phoneController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '(555) 555-5555',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    onChanged: formController.setPhone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('contactEmailField'),
                    controller: _emailController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _validateEmail,
                    onChanged: formController.setEmail,
                  ),
                  const SizedBox(height: 12),
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
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    onChanged: formController.setAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FormSection(
              icon: Icons.notes_outlined,
              title: 'Notes',
              child: TextFormField(
                key: const Key('contactNotesField'),
                controller: _notesController,
                enabled: !isSaving,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter optional contact notes',
                  alignLabelWithHint: true,
                ),
                onChanged: formController.setNotes,
              ),
            ),
            const SizedBox(height: 12),
            _FormSection(
              icon: Icons.people_outline,
              title: 'Contact Status',
              child: SwitchListTile.adaptive(
                key: const Key('contactActiveSwitch'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Active Contact',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Inactive contacts remain available in historical records.',
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryRed,
                value: formState.isActive,
                onChanged: isSaving ? null : formController.setIsActive,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('contactCancelButton'),
                    onPressed: isSaving ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('contactSubmitButton'),
                    onPressed: isSaving ? null : _submit,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving ? 'Saving...' : widget.submitLabel,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _FormIdentityCard extends StatelessWidget {
  const _FormIdentityCard({
    required this.name,
    required this.photoUrl,
    required this.isEditing,
    required this.isUploadingPhoto,
    required this.onPhotoPressed,
  });

  final String name;
  final String? photoUrl;
  final bool isEditing;
  final bool isUploadingPhoto;
  final VoidCallback? onPhotoPressed;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return Card(
      key: const Key('contactFormIdentityCard'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: ClipOval(
                child:
                    url != null &&
                        url.isNotEmpty &&
                        (url.startsWith('http://') ||
                            url.startsWith('https://'))
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _FormInitialsAvatar(name: name),
                      )
                    : _FormInitialsAvatar(name: name),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 5),
              Text(
                url == null || url.isEmpty ? 'No photo added' : 'Contact photo',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('contactPhotoActionButton'),
                onPressed: isUploadingPhoto ? null : onPhotoPressed,
                icon: isUploadingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        url == null || url.isEmpty
                            ? Icons.add_a_photo_outlined
                            : Icons.photo_camera_outlined,
                      ),
                label: Text(
                  isUploadingPhoto
                      ? 'Uploading...'
                      : (url == null || url.isEmpty
                            ? 'Add Photo'
                            : 'Change Photo'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryRed,
                  side: const BorderSide(color: AppTheme.primaryRed),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormInitialsAvatar extends StatelessWidget {
  const _FormInitialsAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F7EC),
      child: Center(
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF12853D),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.navy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
