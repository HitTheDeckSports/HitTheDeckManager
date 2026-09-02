import 'deal.dart';
import 'deal_branch_summary.dart';
import 'deal_status.dart';

class DealTreeProfitSummary {
  DealTreeProfitSummary({
    required this.deal,
    required this.parentTransactionProfitCents,
    required List<DealBranchSummary> branches,
  }) : branches = List.unmodifiable(branches);

  final Deal deal;
  final int parentTransactionProfitCents;
  final List<DealBranchSummary> branches;

  int get realizedBranchProfitCents =>
      branches.fold(0, (sum, branch) => sum + branch.realizedProfitCents);

  int get projectedOpenBranchProfitCents =>
      branches.fold(0, (sum, branch) => sum + branch.projectedOpenProfitCents);

  int get realizedDealProfitCents =>
      parentTransactionProfitCents + realizedBranchProfitCents;

  int get projectedDealProfitCents =>
      realizedDealProfitCents + projectedOpenBranchProfitCents;

  int get openInventoryCount =>
      branches.fold(0, (sum, branch) => sum + branch.openInventoryCount);

  int get realizedSaleCount =>
      branches.fold(0, (sum, branch) => sum + branch.realizedSaleCount);

  DealStatus get status {
    if (openInventoryCount == 0) {
      return DealStatus.completed;
    }

    if (realizedSaleCount == 0 &&
        branches.every((branch) => branch.standardDisposalCount == 0)) {
      return DealStatus.open;
    }

    return DealStatus.partiallyRealized;
  }

  DealBranchSummary? branchFor(String rootChildInventoryItemId) {
    for (final branch in branches) {
      if (branch.rootChildInventoryItemId == rootChildInventoryItemId) {
        return branch;
      }
    }
    return null;
  }
}
