import '../formatting/currency_formatter.dart';

abstract final class AppValidators {
  static String? requiredText(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? nonNegativeMoney(
    String? value, {
    String fieldName = 'Amount',
    bool required = false,
  }) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return required ? '$fieldName is required.' : null;
    }

    final cents = CurrencyFormatter.tryParseToCents(trimmedValue);

    if (cents == null) {
      return 'Enter a valid $fieldName.';
    }

    if (cents < 0) {
      return '$fieldName cannot be negative.';
    }

    return null;
  }

  static String? positiveNumber(
    String? value, {
    String fieldName = 'Value',
    bool required = false,
  }) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return required ? '$fieldName is required.' : null;
    }

    final number = double.tryParse(trimmedValue);

    if (number == null) {
      return 'Enter a valid $fieldName.';
    }

    if (number <= 0) {
      return '$fieldName must be greater than zero.';
    }

    return null;
  }
}
