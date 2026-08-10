/// Access roles available within Hit the Deck Manager.
enum AuthorizedUserRole { owner, user }

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
}
