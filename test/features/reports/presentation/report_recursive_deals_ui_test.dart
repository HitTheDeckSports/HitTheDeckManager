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
  testWidgets('Reports explains Deal economics in business language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
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
    expect(
      find.text('BAT-2609-0001 - Louisville Slugger Atlas'),
      findsOneWidget,
    );
    expect(find.text('Partially Completed'), findsOneWidget);
    expect(find.text('Profit So Far'), findsOneWidget);
    expect(find.text(r'$190.00'), findsOneWidget);
    expect(find.text('Estimated Final Profit'), findsOneWidget);
    expect(find.text(r'$240.00'), findsOneWidget);
    expect(find.text('1 Trade-In Path Still Open'), findsOneWidget);
    expect(find.text('Parent Item'), findsNothing);
    expect(find.text('Branch Realized'), findsNothing);
    expect(find.text('Open Projection'), findsNothing);

    await tester.tap(find.byKey(const Key('recursiveDealExpansion_deal-a')));
    await tester.pumpAndSettle();

    expect(find.text('Original Sale'), findsWidgets);
    expect(find.text('Original Sale Profit'), findsOneWidget);
    expect(find.text(r'$150.00'), findsOneWidget);
    expect(find.text('Trade-In Paths'), findsOneWidget);

    final pathCard = find.byKey(const Key('recursiveDealBranch_item-b'));
    await tester.ensureVisible(pathCard);

    expect(pathCard, findsOneWidget);
    expect(find.text('Trade-In 1'), findsOneWidget);
    expect(find.text('BAT-2609-0002 - Easton Hype Fire'), findsOneWidget);
    expect(find.text('Path Profit So Far'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);
    expect(find.text('Est. Final Path Profit'), findsOneWidget);
    expect(find.text(r'$90.00'), findsOneWidget);
    expect(find.text('Still Active'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('recursiveDealBranchExpansion_item-b')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Received in Trade'), findsOneWidget);
    expect(find.text('Warranty Replacement'), findsOneWidget);
    expect(find.text('BAT-2609-0003 - Marucci CatX2'), findsOneWidget);
    expect(find.text('Current Item'), findsOneWidget);
    expect(find.text('Branch Root'), findsNothing);
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

  const parentItem = InventoryItem(
    id: 'item-parent',
    inventoryNumber: 'BAT-2609-0001',
    category: InventoryCategory.bat,
    brand: 'Louisville Slugger',
    model: 'Atlas',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 10000,
    status: InventoryStatus.sold,
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
        parentInventoryItem: parentItem,
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
