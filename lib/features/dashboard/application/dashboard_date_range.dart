enum DashboardDateRangePreset {
  today,
  last7Days,
  monthToDate,
  last30Days,
  yearToDate,
  custom,
}

class DashboardDateRange {
  const DashboardDateRange({
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

  factory DashboardDateRange.forPreset(
    DashboardDateRangePreset preset, {
    required DateTime asOf,
  }) {
    final today = _dateOnly(asOf);
    final tomorrow = today.add(const Duration(days: 1));

    return switch (preset) {
      DashboardDateRangePreset.today => DashboardDateRange(
        startInclusive: today,
        endExclusive: tomorrow,
        label: 'Today',
      ),
      DashboardDateRangePreset.last7Days => DashboardDateRange(
        startInclusive: today.subtract(const Duration(days: 6)),
        endExclusive: tomorrow,
        label: 'Last 7 Days',
      ),
      DashboardDateRangePreset.monthToDate => DashboardDateRange(
        startInclusive: DateTime(today.year, today.month, 1),
        endExclusive: tomorrow,
        label: 'Month to Date',
      ),
      DashboardDateRangePreset.last30Days => DashboardDateRange(
        startInclusive: today.subtract(const Duration(days: 29)),
        endExclusive: tomorrow,
        label: 'Last 30 Days',
      ),
      DashboardDateRangePreset.yearToDate => DashboardDateRange(
        startInclusive: DateTime(today.year, 1, 1),
        endExclusive: tomorrow,
        label: 'Year to Date',
      ),
      DashboardDateRangePreset.custom => throw ArgumentError(
        'Use DashboardDateRange.custom for a custom range.',
      ),
    };
  }

  factory DashboardDateRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    if (end.isBefore(start)) {
      throw ArgumentError(
        'Custom dashboard end date cannot precede start date.',
      );
    }

    return DashboardDateRange(
      startInclusive: start,
      endExclusive: end.add(const Duration(days: 1)),
      label: 'Custom',
    );
  }
}

class DashboardDateRangeSelection {
  const DashboardDateRangeSelection._({
    required this.preset,
    this.customStartDate,
    this.customEndDate,
  });

  const DashboardDateRangeSelection.monthToDate()
    : this._(preset: DashboardDateRangePreset.monthToDate);

  factory DashboardDateRangeSelection.preset(DashboardDateRangePreset preset) {
    if (preset == DashboardDateRangePreset.custom) {
      throw ArgumentError('Use DashboardDateRangeSelection.custom instead.');
    }

    return DashboardDateRangeSelection._(preset: preset);
  }

  factory DashboardDateRangeSelection.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Validate immediately so an invalid selection can never enter provider
    // state.
    DashboardDateRange.custom(startDate: startDate, endDate: endDate);

    return DashboardDateRangeSelection._(
      preset: DashboardDateRangePreset.custom,
      customStartDate: startDate,
      customEndDate: endDate,
    );
  }

  final DashboardDateRangePreset preset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  DashboardDateRange resolve({required DateTime asOf}) {
    if (preset != DashboardDateRangePreset.custom) {
      return DashboardDateRange.forPreset(preset, asOf: asOf);
    }

    return DashboardDateRange.custom(
      startDate: customStartDate!,
      endDate: customEndDate!,
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
