import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/formatting/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats whole-dollar values', () {
      expect(CurrencyFormatter.formatCents(12500), r'$125.00');
    });

    test('formats values with cents', () {
      expect(CurrencyFormatter.formatCents(12575), r'$125.75');
    });

    test('formats values smaller than one dollar', () {
      expect(CurrencyFormatter.formatCents(5), r'$0.05');
    });

    test('formats negative values', () {
      expect(CurrencyFormatter.formatCents(-250), r'-$2.50');
    });

    test('parses plain dollar input', () {
      expect(CurrencyFormatter.tryParseToCents('125.75'), 12575);
    });

    test('parses currency symbols and commas', () {
      expect(CurrencyFormatter.tryParseToCents(r'$1,250.75'), 125075);
    });

    test('rounds values to the nearest cent', () {
      expect(CurrencyFormatter.tryParseToCents('10.999'), 1100);
    });

    test('returns null for blank input', () {
      expect(CurrencyFormatter.tryParseToCents('   '), isNull);
    });

    test('returns null for invalid input', () {
      expect(CurrencyFormatter.tryParseToCents('abc'), isNull);
    });
  });
}
