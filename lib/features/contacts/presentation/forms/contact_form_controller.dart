import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/contact.dart';
import '../providers/contact_controller.dart';
import 'contact_form_state.dart';

final contactFormControllerProvider =
    NotifierProvider<ContactFormController, ContactFormState>(
      ContactFormController.new,
    );

class ContactFormController extends Notifier<ContactFormState> {
  @override
  ContactFormState build() {
    return const ContactFormState();
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setPhotoUrl(String? photoUrl) {
    state = state.copyWith(photoUrl: photoUrl);
  }

  void loadContact(Contact contact) {
    state = ContactFormState.fromContact(contact);
  }

  Future<Contact?> submit() async {
    final contact = state.toContact();

    if (contact == null) {
      return null;
    }

    final controller = ref.read(contactControllerProvider.notifier);

    final savedContact = state.isEditing
        ? await controller.updateContact(contact)
        : await controller.createContact(contact);

    state = const ContactFormState();

    return savedContact;
  }

  void reset() {
    state = const ContactFormState();
  }
}
