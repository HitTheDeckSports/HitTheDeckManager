abstract final class CurrencyFormatter {
  static String formatCents(int cents) {
    final isNegative = cents < 0;
    final absoluteCents = cents.abs();
    final dollars = absoluteCents ~/ 100;
    final remainingCents = absoluteCents % 100;

    final formatted = '\$$dollars.${remainingCents.toString().padLeft(2, '0')}';

    return isNegative ? '-$formatted' : formatted;
  }

  static int? tryParseToCents(String input) {
    final normalized = input.trim().replaceAll(r'$', '').replaceAll(',', '');

    if (normalized.isEmpty) {
      return null;
    }

    final value = double.tryParse(normalized);

    if (value == null) {
      return null;
    }

    return (value * 100).round();
  }
}
