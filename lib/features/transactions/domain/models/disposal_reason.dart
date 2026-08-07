enum DisposalReason {
  damagedBeyondRepair,
  obsolete,
  donated,
  lostOrStolen,
  warrantyReplacement,
  other,
}

extension DisposalReasonLabel on DisposalReason {
  String get label => switch (this) {
    DisposalReason.damagedBeyondRepair => 'Damaged Beyond Repair',
    DisposalReason.obsolete => 'Obsolete',
    DisposalReason.donated => 'Donated',
    DisposalReason.lostOrStolen => 'Lost or Stolen',
    DisposalReason.warrantyReplacement => 'Warranty Replacement',
    DisposalReason.other => 'Other',
  };
}

extension DisposalReasonRules on DisposalReason {
  bool get requiresReplacementDeal =>
      this == DisposalReason.warrantyReplacement;
}
