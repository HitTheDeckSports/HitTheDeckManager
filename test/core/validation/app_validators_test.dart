import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/validation/app_validators.dart';

void main() {
  group('AppValidators.requiredText', () {
    test('returns an error for null input', () {
      expect(
        AppValidators.requiredText(null, fieldName: 'Brand'),
        'Brand is required.',
      );
    });

    test('returns an error for blank input', () {
      expect(
        AppValidators.requiredText('   ', fieldName: 'Brand'),
        'Brand is required.',
      );
    });

    test('returns null for valid text', () {
      expect(AppValidators.requiredText('Combat', fieldName: 'Brand'), isNull);
    });
  });

  group('AppValidators.nonNegativeMoney', () {
    test('allows blank optional input', () {
      expect(
        AppValidators.nonNegativeMoney('', fieldName: 'Asking price'),
        isNull,
      );
    });

    test('requires input when configured as required', () {
      expect(
        AppValidators.nonNegativeMoney(
          '',
          fieldName: 'Acquisition value',
          required: true,
        ),
        'Acquisition value is required.',
      );
    });

    test('accepts valid currency input', () {
      expect(
        AppValidators.nonNegativeMoney(r'$1,250.75', fieldName: 'Asking price'),
        isNull,
      );
    });

    test('rejects invalid currency input', () {
      expect(
        AppValidators.nonNegativeMoney('abc', fieldName: 'Asking price'),
        'Enter a valid Asking price.',
      );
    });

    test('rejects negative currency input', () {
      expect(
        AppValidators.nonNegativeMoney('-10.00', fieldName: 'Asking price'),
        'Asking price cannot be negative.',
      );
    });
  });

  group('AppValidators.positiveNumber', () {
    test('allows blank optional input', () {
      expect(AppValidators.positiveNumber('', fieldName: 'Bat length'), isNull);
    });

    test('requires input when configured as required', () {
      expect(
        AppValidators.positiveNumber(
          '',
          fieldName: 'Bat length',
          required: true,
        ),
        'Bat length is required.',
      );
    });

    test('accepts a positive number', () {
      expect(
        AppValidators.positiveNumber('32', fieldName: 'Bat length'),
        isNull,
      );
    });

    test('rejects invalid numeric input', () {
      expect(
        AppValidators.positiveNumber('abc', fieldName: 'Bat length'),
        'Enter a valid Bat length.',
      );
    });

    test('rejects zero', () {
      expect(
        AppValidators.positiveNumber('0', fieldName: 'Bat length'),
        'Bat length must be greater than zero.',
      );
    });

    test('rejects negative numbers', () {
      expect(
        AppValidators.positiveNumber('-5', fieldName: 'Bat length'),
        'Bat length must be greater than zero.',
      );
    });
  });
}
