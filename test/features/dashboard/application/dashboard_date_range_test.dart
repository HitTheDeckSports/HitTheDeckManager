import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_date_range.dart';

void main() {
  group('DashboardDateRange', () {
    final asOf = DateTime(2026, 8, 24, 11, 15);

    test('month to date is the default approved period', () {
      final range = DashboardDateRange.forPreset(
        DashboardDateRangePreset.monthToDate,
        asOf: asOf,
      );

      expect(range.label, 'Month to Date');
      expect(range.startInclusive, DateTime(2026, 8, 1));
      expect(range.endExclusive, DateTime(2026, 8, 25));
      expect(range.contains(DateTime(2026, 8, 1)), isTrue);
      expect(range.contains(DateTime(2026, 7, 31, 23, 59)), isFalse);
      expect(range.contains(DateTime(2026, 8, 25)), isFalse);
    });

    test('Today includes only the current calendar date', () {
      final range = DashboardDateRange.forPreset(
        DashboardDateRangePreset.today,
        asOf: asOf,
      );

      expect(range.startInclusive, DateTime(2026, 8, 24));
      expect(range.endExclusive, DateTime(2026, 8, 25));
    });

    test('Last 7 Days includes today plus the prior six days', () {
      final range = DashboardDateRange.forPreset(
        DashboardDateRangePreset.last7Days,
        asOf: asOf,
      );

      expect(range.startInclusive, DateTime(2026, 8, 18));
      expect(range.endExclusive, DateTime(2026, 8, 25));
    });

    test('Last 30 Days includes today plus the prior 29 days', () {
      final range = DashboardDateRange.forPreset(
        DashboardDateRangePreset.last30Days,
        asOf: asOf,
      );

      expect(range.startInclusive, DateTime(2026, 7, 26));
      expect(range.endExclusive, DateTime(2026, 8, 25));
    });

    test('Year to Date begins January 1', () {
      final range = DashboardDateRange.forPreset(
        DashboardDateRangePreset.yearToDate,
        asOf: asOf,
      );

      expect(range.startInclusive, DateTime(2026, 1, 1));
      expect(range.endExclusive, DateTime(2026, 8, 25));
    });

    test('custom range includes both selected calendar dates', () {
      final range = DashboardDateRange.custom(
        startDate: DateTime(2026, 6, 10, 15),
        endDate: DateTime(2026, 6, 12, 8),
      );

      expect(range.startInclusive, DateTime(2026, 6, 10));
      expect(range.endExclusive, DateTime(2026, 6, 13));
      expect(range.contains(DateTime(2026, 6, 12, 23, 59)), isTrue);
    });

    test('custom range rejects end before start', () {
      expect(
        () => DashboardDateRange.custom(
          startDate: DateTime(2026, 6, 12),
          endDate: DateTime(2026, 6, 10),
        ),
        throwsArgumentError,
      );
    });
  });
}
