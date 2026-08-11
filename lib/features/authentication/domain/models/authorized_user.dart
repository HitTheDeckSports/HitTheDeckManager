/// Access roles available within Hit the Deck Manager.
enum AuthorizedUserRole { owner, admin, user }

/// Application-level representation of an approved Hit the Deck Manager user.
class AuthorizedUser {
  const AuthorizedUser({
    required this.email,
    required this.role,
    required this.active,
  });

  final String email;
  final AuthorizedUserRole role;
  final bool active;

  bool get isOwner => role == AuthorizedUserRole.owner;
  bool get isAdmin =>
      role == AuthorizedUserRole.owner || role == AuthorizedUserRole.admin;

  AuthorizedUser copyWith({
    String? email,
    AuthorizedUserRole? role,
    bool? active,
  }) {
    return AuthorizedUser(
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthorizedUser &&
            runtimeType == other.runtimeType &&
            email == other.email &&
            role == other.role &&
            active == other.active;
  }

  @override
  int get hashCode => Object.hash(email, role, active);
}
