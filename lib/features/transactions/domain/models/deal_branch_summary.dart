class DealBranchSummary {
  const DealBranchSummary({
    required this.rootChildInventoryItemId,
    required this.realizedProfitCents,
    required this.projectedOpenProfitCents,
    required this.realizedSaleCount,
    required this.standardDisposalCount,
    required this.openInventoryCount,
  });

  final String rootChildInventoryItemId;

  /// Profit/loss already realized within this branch.
  ///
  /// Includes completed sales, repair costs stranded on warranty-replaced
  /// predecessors, and losses from standard disposals.
  final int realizedProfitCents;

  /// Incremental projected profit/loss from inventory that is still open.
  ///
  /// Each open item uses Asking Price - Acquisition Value - Repair Costs.
  /// Blank Asking Price contributes $0 projected profit while the item remains
  /// counted as open.
  final int projectedOpenProfitCents;

  int get projectedBranchProfitCents =>
      realizedProfitCents + projectedOpenProfitCents;

  final int realizedSaleCount;
  final int standardDisposalCount;
  final int openInventoryCount;

  bool get isFullyRealized => openInventoryCount == 0;
}
