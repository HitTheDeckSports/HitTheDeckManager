import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/reports/application/report_date_range.dart';

void main() {
  test('report date ranges use inclusive calendar dates', () {
    final mtd = ReportDateRange.forPreset(
      ReportDateRangePreset.monthToDate,
      asOf: DateTime(2026, 8, 24, 14),
    );
    expect(mtd.startInclusive, DateTime(2026, 8, 1));
    expect(mtd.endExclusive, DateTime(2026, 8, 25));
    expect(mtd.contains(DateTime(2026, 8, 24, 23, 59)), isTrue);

    final custom = ReportDateRange.custom(
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 12),
    );
    expect(custom.contains(DateTime(2026, 7, 12, 23, 59)), isTrue);
    expect(custom.contains(DateTime(2026, 7, 13)), isFalse);
  });
}
