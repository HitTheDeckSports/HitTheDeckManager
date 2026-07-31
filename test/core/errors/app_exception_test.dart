import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';

void main() {
  group('AppException', () {
    test('returns its user-facing message from toString', () {
      const exception = ValidationException('Brand is required.');

      expect(exception.message, 'Brand is required.');
      expect(exception.toString(), 'Brand is required.');
    });

    test('stores an optional original cause', () {
      final cause = Exception('Original error');

      final exception = UnexpectedException(
        'An unexpected error occurred.',
        cause: cause,
      );

      expect(exception.cause, same(cause));
    });

    test('specific exception types can be distinguished', () {
      const validation = ValidationException('Invalid value');
      const notFound = NotFoundException('Missing record');
      const duplicate = DuplicateException('Duplicate record');
      const network = NetworkException('Network unavailable');
      const permission = PermissionException('Access denied');
      const unexpected = UnexpectedException('Unexpected error');

      expect(validation, isA<ValidationException>());
      expect(notFound, isA<NotFoundException>());
      expect(duplicate, isA<DuplicateException>());
      expect(network, isA<NetworkException>());
      expect(permission, isA<PermissionException>());
      expect(unexpected, isA<UnexpectedException>());

      expect(validation, isA<AppException>());
      expect(network, isA<AppException>());
    });
  });
}
