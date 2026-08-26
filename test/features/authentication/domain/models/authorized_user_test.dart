import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';

void main() {
  group('AuthorizedUser', () {
    test('owner is both owner and admin', () {
      const user = AuthorizedUser(
        email: 'sales.hitthedecksports@gmail.com',
        role: AuthorizedUserRole.owner,
        active: true,
      );

      expect(user.isOwner, isTrue);
      expect(user.isAdmin, isTrue);
    });

    test('admin is admin but not owner', () {
      const user = AuthorizedUser(
        email: 'admin@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      expect(user.isOwner, isFalse);
      expect(user.isAdmin, isTrue);
    });

    test('copyWith changes only supplied values', () {
      const original = AuthorizedUser(
        email: 'admin@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      final updated = original.copyWith(active: false);

      expect(updated.email, original.email);
      expect(updated.role, original.role);
      expect(updated.active, isFalse);
    });

    test('equal admins compare as equal', () {
      const first = AuthorizedUser(
        email: 'admin@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      const second = AuthorizedUser(
        email: 'admin@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different admins do not compare as equal', () {
      const first = AuthorizedUser(
        email: 'first@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      const second = AuthorizedUser(
        email: 'second@example.com',
        role: AuthorizedUserRole.admin,
        active: true,
      );

      expect(first, isNot(second));
    });
  });
}
