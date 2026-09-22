const _unset = Object();

class Contact {
  const Contact({
    required this.name,
    this.id,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.photoUrl,
    this.isActive = true,
  });

  /// Database identifier assigned after the contact is saved.
  final String? id;

  /// Contact name is the only required user-entered field.
  final String name;

  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  /// Reference to the contact's optional profile photo.
  final String? photoUrl;

  /// Inactive contacts remain available for historical business records.
  final bool isActive;

  bool get isValid => validationErrors.isEmpty;

  List<String> get validationErrors {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Name is required.');
    }

    final trimmedEmail = email?.trim() ?? '';

    if (trimmedEmail.isNotEmpty && !_looksLikeEmail(trimmedEmail)) {
      errors.add('Enter a valid email address.');
    }

    return List.unmodifiable(errors);
  }

  Contact copyWith({
    Object? id = _unset,
    String? name,
    Object? phone = _unset,
    Object? email = _unset,
    Object? address = _unset,
    Object? notes = _unset,
    Object? photoUrl = _unset,
    bool? isActive,
  }) {
    return Contact(
      id: identical(id, _unset) ? this.id : id as String?,
      name: name ?? this.name,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      address: identical(address, _unset) ? this.address : address as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      photoUrl: identical(photoUrl, _unset)
          ? this.photoUrl
          : photoUrl as String?,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Contact) {
      return false;
    }

    if (id == null || other.id == null) {
      return false;
    }

    return id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}

bool _looksLikeEmail(String value) {
  final atIndex = value.indexOf('@');
  final lastDotIndex = value.lastIndexOf('.');

  return atIndex > 0 &&
      lastDotIndex > atIndex + 1 &&
      lastDotIndex < value.length - 1;
}
