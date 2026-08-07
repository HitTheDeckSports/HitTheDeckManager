import 'deal.dart';
import 'deal_status.dart';

class DealSummary {
  const DealSummary({
    required this.deal,
    required this.status,
    required this.parentTransactionProfitCents,
    required this.realizedChildProfitCents,
    required this.projectedChildProfitCents,
    required this.realizedDealProfitCents,
    required this.projectedDealProfitCents,
    required this.realizedChildCount,
    required this.openChildCount,
  });

  final Deal deal;
  final DealStatus status;

  /// Profit reported by the original parent sale.
  final int parentTransactionProfitCents;

  /// Profit from child inventory items that have subsequently sold.
  final int realizedChildProfitCents;

  /// Potential profit from unsold child inventory using current asking prices.
  final int projectedChildProfitCents;

  /// Parent profit plus profit from completed child sales.
  final int realizedDealProfitCents;

  /// Realized Deal profit plus projected profit from unsold children.
  final int projectedDealProfitCents;

  final int realizedChildCount;
  final int openChildCount;
}
