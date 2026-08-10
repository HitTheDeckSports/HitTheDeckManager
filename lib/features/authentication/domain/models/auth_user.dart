/// Application-level representation of an authenticated Hit the Deck user.
///
/// Keeping Firebase-specific types out of the domain layer prevents the rest
/// of the application from depending directly on Firebase Authentication.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            email == other.email &&
            displayName == other.displayName &&
            photoUrl == other.photoUrl;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);
}
