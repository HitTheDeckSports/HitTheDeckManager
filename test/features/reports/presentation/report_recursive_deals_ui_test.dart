import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/deal_rollup_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/financial_performance_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/inventory_aging_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/recursive_deal_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/reports_snapshot.dart';
import 'package:hit_the_deck_manager/features/reports/application/sales_analysis_report.dart';
import 'package:hit_the_deck_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:hit_the_deck_manager/features/reports/presentation/report_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_branch_summary.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_lineage_edge_type.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_lineage_node.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_lineage_tree.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_tree_profit_summary.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  testWidgets('Reports shows recursive Deal and branch profitability', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAppPermissionsProvider.overrideWithValue(
            const AppPermissions.ownerOrAdmin(),
          ),
          reportsSnapshotProvider.overrideWithValue(
            AsyncValue.data(_recursiveSnapshot()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final dealCard = find.byKey(const Key('recursiveDealCard_deal-a'));
    await tester.ensureVisible(dealCard);

    expect(dealCard, findsOneWidget);
    expect(find.text('item-parent'), findsOneWidget);
    expect(find.text(r'$240.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('recursiveDealExpansion_deal-a')));
    await tester.pumpAndSettle();

    final branchCard = find.byKey(const Key('recursiveDealBranch_item-b'));
    await tester.ensureVisible(branchCard);

    expect(branchCard, findsOneWidget);
    expect(find.text('BAT-2609-0002 - Easton Hype Fire'), findsOneWidget);
    expect(find.text(r'$90.00'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('recursiveDealBranchExpansion_item-b')),
    );
    await tester.pumpAndSettle();

    expect(find.text('BAT-2609-0003 - Marucci CatX2'), findsOneWidget);
    expect(find.text('Warranty'), findsOneWidget);
  });
}

ReportsSnapshot _recursiveSnapshot() {
  const deal = Deal(
    id: 'deal-a',
    parentSaleTransactionId: 'sale-parent',
    childInventoryItemIds: ['item-b'],
    lineageInventoryItemIds: ['item-b', 'item-w'],
  );

  final parentSale = SaleTransaction(
    id: 'sale-parent',
    inventoryItemId: 'item-parent',
    salePriceCents: 25000,
    saleDate: DateTime(2026, 9, 1),
    paymentMethod: PaymentMethod.cash,
    acquisitionValueCents: 10000,
  );

  const itemB = InventoryItem(
    id: 'item-b',
    inventoryNumber: 'BAT-2609-0002',
    category: InventoryCategory.bat,
    brand: 'Easton',
    model: 'Hype Fire',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 12000,
    status: InventoryStatus.disposed,
  );

  const itemW = InventoryItem(
    id: 'item-w',
    inventoryNumber: 'BAT-2609-0003',
    category: InventoryCategory.bat,
    brand: 'Marucci',
    model: 'CatX2',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 12000,
    askingPriceCents: 17000,
  );

  final tree = DealLineageTree(
    deal: deal,
    nodes: const [
      DealLineageNode(
        inventoryItemId: 'item-b',
        rootChildInventoryItemId: 'item-b',
        depth: 0,
      ),
      DealLineageNode(
        inventoryItemId: 'item-w',
        rootChildInventoryItemId: 'item-b',
        parentInventoryItemId: 'item-b',
        edgeTypeFromParent: DealLineageEdgeType.warrantyReplacement,
        depth: 1,
      ),
    ],
  );

  final summary = DealTreeProfitSummary(
    deal: deal,
    parentTransactionProfitCents: 15000,
    branches: const [
      DealBranchSummary(
        rootChildInventoryItemId: 'item-b',
        realizedProfitCents: 4000,
        projectedOpenProfitCents: 5000,
        realizedSaleCount: 1,
        standardDisposalCount: 0,
        openInventoryCount: 1,
      ),
    ],
  );

  final recursiveReport = RecursiveDealReport(
    rows: [
      RecursiveDealReportRow(
        deal: deal,
        parentSale: parentSale,
        tree: tree,
        summary: summary,
        lineageInventoryItems: const [itemB, itemW],
      ),
    ],
  );

  return ReportsSnapshot(
    financialPerformance: const FinancialPerformanceReport(
      rangeLabel: 'Month to Date',
      revenueCents: 0,
      costCents: 0,
      profitCents: 0,
      grossMargin: 0,
      unitsSold: 0,
      monthlyTrend: [],
      saleIds: [],
    ),
    salesByCategory: const SalesAnalysisReport(
      dimension: SalesAnalysisDimension.category,
      rows: [],
    ),
    salesByBrand: const SalesAnalysisReport(
      dimension: SalesAnalysisDimension.brand,
      rows: [],
    ),
    salesByModel: const SalesAnalysisReport(
      dimension: SalesAnalysisDimension.model,
      rows: [],
    ),
    inventoryAging: const InventoryAgingReport(
      rows: [],
      unclassifiedItemIds: [],
    ),
    deals: const DealRollupReport(rows: []),
    recursiveDeals: recursiveReport,
  );
}
