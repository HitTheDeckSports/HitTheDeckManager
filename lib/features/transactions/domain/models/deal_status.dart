enum DealStatus { open, partiallyRealized, completed }

extension DealStatusLabel on DealStatus {
  String get label {
    return switch (this) {
      DealStatus.open => 'Open',
      DealStatus.partiallyRealized => 'Partially Realized',
      DealStatus.completed => 'Completed',
    };
  }
}
