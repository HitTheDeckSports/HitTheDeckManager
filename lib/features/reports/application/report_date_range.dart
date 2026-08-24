enum ReportDateRangePreset {
  today,
  last7Days,
  monthToDate,
  last30Days,
  yearToDate,
  custom,
}

class ReportDateRange {
  const ReportDateRange({
    required this.startInclusive,
    required this.endExclusive,
    required this.label,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;
  final String label;

  bool contains(DateTime value) {
    return !value.isBefore(startInclusive) && value.isBefore(endExclusive);
  }

  factory ReportDateRange.forPreset(
    ReportDateRangePreset preset, {
    required DateTime asOf,
  }) {
    final today = _dateOnly(asOf);
    final tomorrow = today.add(const Duration(days: 1));

    return switch (preset) {
      ReportDateRangePreset.today => ReportDateRange(
        startInclusive: today,
        endExclusive: tomorrow,
        label: 'Today',
      ),
      ReportDateRangePreset.last7Days => ReportDateRange(
        startInclusive: today.subtract(const Duration(days: 6)),
        endExclusive: tomorrow,
        label: 'Last 7 Days',
      ),
      ReportDateRangePreset.monthToDate => ReportDateRange(
        startInclusive: DateTime(today.year, today.month, 1),
        endExclusive: tomorrow,
        label: 'Month to Date',
      ),
      ReportDateRangePreset.last30Days => ReportDateRange(
        startInclusive: today.subtract(const Duration(days: 29)),
        endExclusive: tomorrow,
        label: 'Last 30 Days',
      ),
      ReportDateRangePreset.yearToDate => ReportDateRange(
        startInclusive: DateTime(today.year, 1, 1),
        endExclusive: tomorrow,
        label: 'Year to Date',
      ),
      ReportDateRangePreset.custom => throw ArgumentError(
        'Use ReportDateRange.custom for a custom range.',
      ),
    };
  }

  factory ReportDateRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    if (end.isBefore(start)) {
      throw ArgumentError('Custom report end date cannot precede start date.');
    }

    return ReportDateRange(
      startInclusive: start,
      endExclusive: end.add(const Duration(days: 1)),
      label: 'Custom',
    );
  }
}

class ReportDateRangeSelection {
  const ReportDateRangeSelection._({
    required this.preset,
    this.customStartDate,
    this.customEndDate,
  });

  const ReportDateRangeSelection.monthToDate()
    : this._(preset: ReportDateRangePreset.monthToDate);

  factory ReportDateRangeSelection.preset(ReportDateRangePreset preset) {
    if (preset == ReportDateRangePreset.custom) {
      throw ArgumentError('Use ReportDateRangeSelection.custom instead.');
    }
    return ReportDateRangeSelection._(preset: preset);
  }

  factory ReportDateRangeSelection.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    ReportDateRange.custom(startDate: startDate, endDate: endDate);
    return ReportDateRangeSelection._(
      preset: ReportDateRangePreset.custom,
      customStartDate: startDate,
      customEndDate: endDate,
    );
  }

  final ReportDateRangePreset preset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  ReportDateRange resolve({required DateTime asOf}) {
    if (preset != ReportDateRangePreset.custom) {
      return ReportDateRange.forPreset(preset, asOf: asOf);
    }
    return ReportDateRange.custom(
      startDate: customStartDate!,
      endDate: customEndDate!,
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
