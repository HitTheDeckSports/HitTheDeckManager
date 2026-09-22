import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../domain/models/deal_status.dart';
import 'providers/deal_detail_analysis_provider.dart';
import 'widgets/inventory_summary_card.dart';

class DealDetailScreen extends ConsumerStatefulWidget {
  const DealDetailScreen({required this.dealId, super.key});
  final String dealId;

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(dealDetailAnalysisProvider(widget.dealId));
    final permissions = ref.watch(currentAppPermissionsProvider);

    return analysisAsync.when(
      loading: () => const AppPage(
        title: 'Deal Details',
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading Deal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Deal Details',
        showHeader: false,
        compact: true,
        child: AppErrorState(
          message: 'Unable to load Deal.',
          details: error.toString(),
          onRetry: () =>
              ref.invalidate(dealDetailAnalysisProvider(widget.dealId)),
        ),
      ),
      data: (viewModel) {
        if (viewModel == null) {
          return const AppPage(
            title: 'Deal Details',
            showHeader: false,
            compact: true,
            child: AppEmptyState(
              icon: Icons.handshake_outlined,
              title: 'Deal not found.',
              message: 'The Deal may have been removed.',
            ),
          );
        }

        return AppPage(
          title: 'Deal Details',
          showHeader: false,
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DealIdentityCard(viewModel: viewModel),
              const SizedBox(height: 12),
              if (permissions.canViewFinancialData)
                _HeadlineSummary(viewModel: viewModel)
              else
                _StatusSummary(viewModel: viewModel),
              const SizedBox(height: 12),
              _DealTabs(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
              const SizedBox(height: 12),
              switch (_selectedTab) {
                0 => _DealTreeTab(viewModel: viewModel),
                1 =>
                  permissions.canViewFinancialData
                      ? _FinancialsTab(
                          viewModel: viewModel,
                          onBranchSelected: () =>
                              setState(() => _selectedTab = 0),
                        )
                      : const _FinancialHiddenCard(),
                _ => _TransactionsTab(viewModel: viewModel),
              },
            ],
          ),
        );
      },
    );
  }
}

class _DealIdentityCard extends StatelessWidget {
  const _DealIdentityCard({required this.viewModel});
  final DealDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final date = viewModel.deal.createdAt;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_rounded, color: Color(0xFF6E23B6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.displayNumber == null
                        ? 'Deal'
                        : 'Deal #${viewModel.displayNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF082A4A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _Pill(
                        text: viewModel.financial.status.label,
                        foreground: const Color(0xFF6E23B6),
                        background: const Color(0xFFF3E8FF),
                      ),
                      const Spacer(),
                      if (date != null)
                        Text(
                          _date(date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF5F6D7E)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadlineSummary extends StatelessWidget {
  const _HeadlineSummary({required this.viewModel});
  final DealDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'CURRENT PROFIT',
                value: CurrencyFormatter.formatCents(
                  viewModel.financial.currentProfitCents,
                ),
                valueColor: viewModel.financial.currentProfitCents < 0
                    ? const Color(0xFFC62828)
                    : const Color(0xFF15803D),
              ),
            ),
            const _VerticalRule(),
            Expanded(
              child: _Metric(
                label: 'PROJECTED PROFIT',
                value: CurrencyFormatter.formatCents(
                  viewModel.financial.projectedProfitCents,
                ),
                valueColor: viewModel.financial.projectedProfitCents < 0
                    ? const Color(0xFFC62828)
                    : const Color(0xFF1174C2),
              ),
            ),
            const _VerticalRule(),
            Expanded(
              child: _Metric(
                label: 'OPEN BRANCHES',
                value: viewModel.financial.openBranchCount.toString(),
                valueColor: const Color(0xFF082A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.viewModel});
  final DealDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined),
          const SizedBox(width: 10),
          Text('${viewModel.financial.openBranchCount} open branches'),
        ],
      ),
    ),
  );
}

class _DealTabs extends StatelessWidget {
  const _DealTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Deal Tree', 'Financials', 'Transactions'];
    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                key: Key('dealTab-$index'),
                onTap: () => onChanged(index),
                child: Container(
                  padding: const EdgeInsets.only(top: 13, bottom: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedIndex == index
                            ? const Color(0xFFED1C24)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedIndex == index
                          ? const Color(0xFF082A4A)
                          : const Color(0xFF697789),
                      fontWeight: selectedIndex == index
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DealTreeTab extends StatelessWidget {
  const _DealTreeTab({required this.viewModel});
  final DealDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(icon: Icons.account_tree_outlined, title: 'Deal Tree'),
        InventorySummaryCard.full(
          item: viewModel.rootItem,
          contextLabel: 'Original Sale',
          contextDate: _date(viewModel.parentSale.saleDate),
          statusLabel: 'Sold',
          onTap: viewModel.rootItem.id == null
              ? null
              : () => context.pushNamed(
                  AppRouteNames.inventoryDetail,
                  pathParameters: {'itemId': viewModel.rootItem.id!},
                ),
        ),
        const SizedBox(height: 8),
        _CashEvent(
          label: 'Cash Received',
          cents: viewModel.parentSale.cashReceivedCents,
          onTap: viewModel.parentSale.id == null
              ? null
              : () => context.pushNamed(
                  AppRouteNames.transactionDetail,
                  pathParameters: {'transactionId': viewModel.parentSale.id!},
                ),
        ),
        const SizedBox(height: 12),
        for (final branch in viewModel.branches) ...[
          _BranchTreeCard(branch: branch),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BranchTreeCard extends StatelessWidget {
  const _BranchTreeCard({required this.branch});
  final DealBranchViewModel branch;

  @override
  Widget build(BuildContext context) {
    final financial = branch.financial;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF082A4A),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Branch ${branch.index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Pill(
                  text: financial.isClosed
                      ? 'Closed'
                      : '${financial.openInventoryCount} Open',
                  foreground: financial.isClosed
                      ? const Color(0xFF126B38)
                      : const Color(0xFF8A5A00),
                  background: financial.isClosed
                      ? const Color(0xFFE1F4E7)
                      : const Color(0xFFFFF0C2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < branch.items.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFF8793A2),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                  ],
                  _BranchItem(itemView: branch.items[i]),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'REALIZED PROFIT',
                        value: CurrencyFormatter.formatCents(
                          financial.realizedProfitCents,
                        ),
                        valueColor: financial.realizedProfitCents < 0
                            ? const Color(0xFFC62828)
                            : const Color(0xFF15803D),
                      ),
                    ),
                    const _VerticalRule(),
                    Expanded(
                      child: _Metric(
                        label: 'PROJECTED PROFIT',
                        value: CurrencyFormatter.formatCents(
                          financial.projectedProfitCents,
                        ),
                        valueColor: financial.projectedProfitCents < 0
                            ? const Color(0xFFC62828)
                            : const Color(0xFF1174C2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchItem extends StatelessWidget {
  const _BranchItem({required this.itemView});
  final DealTreeItemViewModel itemView;

  @override
  Widget build(BuildContext context) {
    final item = itemView.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InventorySummaryCard.compact(
          item: item,
          valueLabel:
              'Acquisition Value: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}',
          onTap: item.id == null
              ? null
              : () => context.pushNamed(
                  AppRouteNames.inventoryDetail,
                  pathParameters: {'itemId': item.id!},
                ),
        ),
        if (itemView.repairCostCents > 0)
          _InlineEvent(
            icon: Icons.build_outlined,
            label: 'Repairs',
            value: CurrencyFormatter.formatCents(itemView.repairCostCents),
            color: const Color(0xFF7C5A00),
          ),
        if (itemView.sale != null)
          _CashEvent(
            label: 'Sold • Cash Received',
            cents: itemView.sale!.cashReceivedCents,
            onTap: itemView.sale!.id == null
                ? null
                : () => context.pushNamed(
                    AppRouteNames.transactionDetail,
                    pathParameters: {'transactionId': itemView.sale!.id!},
                  ),
          ),
        if (itemView.disposal != null)
          _InlineEvent(
            icon: Icons.delete_outline,
            label: 'Disposed',
            value: itemView.disposal!.reason.name,
            color: const Color(0xFF8A3B3B),
          ),
        if (itemView.warrantyReplacement != null)
          const _InlineEvent(
            icon: Icons.autorenew_rounded,
            label: 'Warranty Replacement',
            value: 'Continues in this branch',
            color: Color(0xFF1174C2),
          ),
        if (itemView.sale == null && itemView.disposal == null)
          _InlineEvent(
            icon: Icons.inventory_2_outlined,
            label: 'In Inventory',
            value:
                'Asking: ${CurrencyFormatter.formatCents(item.askingPriceCents ?? 0)}',
            color: const Color(0xFF8A5A00),
          ),
        if (itemView.nestedDeal != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              key: Key('nestedDeal-${itemView.nestedDeal!.id}'),
              onTap: itemView.nestedDeal!.id == null
                  ? null
                  : () => context.pushNamed(
                      AppRouteNames.dealDetail,
                      pathParameters: {'dealId': itemView.nestedDeal!.id!},
                    ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8B8F5)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Color(0xFF6E23B6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemView.nestedDealDisplayNumber == null
                                ? 'Nested Deal'
                                : 'Deal #${itemView.nestedDealDisplayNumber}',
                            style: const TextStyle(
                              color: Color(0xFF5A1D91),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Created from this sale',
                            style: TextStyle(color: Color(0xFF6F5A7F)),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'View Deal',
                      style: TextStyle(
                        color: Color(0xFF6E23B6),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF6E23B6)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FinancialsTab extends StatelessWidget {
  const _FinancialsTab({
    required this.viewModel,
    required this.onBranchSelected,
  });
  final DealDetailViewModel viewModel;
  final VoidCallback onBranchSelected;

  @override
  Widget build(BuildContext context) {
    final f = viewModel.financial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          icon: Icons.attach_money_rounded,
          title: 'Deal Financials',
          children: [
            _FinancialRow(
              label: 'Deal Current Profit',
              value: CurrencyFormatter.formatCents(f.currentProfitCents),
              strong: true,
            ),
            const Divider(),
            _FinancialRow(
              label: 'Deal Projected Profit',
              value: CurrencyFormatter.formatCents(f.projectedProfitCents),
              strong: true,
            ),
            const Divider(),
            _FinancialRow(
              label: 'Total Cash Received',
              value: CurrencyFormatter.formatCents(f.totalCashReceivedCents),
            ),
            const Divider(),
            _FinancialRow(
              label: 'Total Cash Paid',
              value: CurrencyFormatter.formatCents(f.totalCashPaidCents),
            ),
            const Divider(),
            _FinancialRow(
              label: 'Original Item Acquisition Cost',
              value: CurrencyFormatter.formatCents(f.rootAcquisitionCostCents),
            ),
            const Divider(),
            _FinancialRow(
              label: 'Total Repair Costs',
              value: CurrencyFormatter.formatCents(f.totalRepairCostCents),
            ),
            const Divider(),
            _FinancialRow(
              label: 'Projected Open Inventory Value',
              value: CurrencyFormatter.formatCents(
                f.projectedOpenInventoryValueCents,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          icon: Icons.account_tree_outlined,
          title: 'Branch Profitability',
        ),
        for (final branch in viewModel.branches) ...[
          InkWell(
            onTap: onBranchSelected,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Branch ${branch.index} — ${inventoryEquipmentName(branch.rootItem)}',
                            style: const TextStyle(
                              color: Color(0xFF082A4A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _Pill(
                          text: branch.financial.isClosed
                              ? 'Closed'
                              : '${branch.financial.openInventoryCount} Open',
                          foreground: branch.financial.isClosed
                              ? const Color(0xFF126B38)
                              : const Color(0xFF8A5A00),
                          background: branch.financial.isClosed
                              ? const Color(0xFFE1F4E7)
                              : const Color(0xFFFFF0C2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'REALIZED PROFIT',
                            value: CurrencyFormatter.formatCents(
                              branch.financial.realizedProfitCents,
                            ),
                            valueColor: branch.financial.realizedProfitCents < 0
                                ? const Color(0xFFC62828)
                                : const Color(0xFF15803D),
                          ),
                        ),
                        const _VerticalRule(),
                        Expanded(
                          child: _Metric(
                            label: 'PROJECTED PROFIT',
                            value: CurrencyFormatter.formatCents(
                              branch.financial.projectedProfitCents,
                            ),
                            valueColor:
                                branch.financial.projectedProfitCents < 0
                                ? const Color(0xFFC62828)
                                : const Color(0xFF1174C2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.viewModel});
  final DealDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.timeline_rounded,
      title: 'Deal Transactions',
      children: [
        for (var i = 0; i < viewModel.activities.length; i++) ...[
          if (i > 0) const Divider(height: 18),
          _ActivityRow(activity: viewModel.activities[i]),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final DealActivityViewModel activity;

  @override
  Widget build(BuildContext context) {
    final visual = _activityVisual(activity.iconKind);
    return InkWell(
      onTap: () => _openActivity(context, activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: visual.$2,
                shape: BoxShape.circle,
              ),
              child: Icon(visual.$1, color: visual.$3, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Color(0xFF082A4A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle,
                    style: const TextStyle(color: Color(0xFF5F6D7E)),
                  ),
                  Text(
                    _date(activity.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8793A2),
                    ),
                  ),
                ],
              ),
            ),
            if (activity.target != DealActivityTarget.none)
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _FinancialHiddenCard extends StatelessWidget {
  const _FinancialHiddenCard();

  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Text(
        'Financial Deal data is not available for this profile.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF082A4A), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF082A4A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFF082A4A),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5F6D7E),
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        style: TextStyle(
          color: const Color(0xFF082A4A),
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    ],
  );
}

class _CashEvent extends StatelessWidget {
  const _CashEvent({required this.label, required this.cents, this.onTap});
  final String label;
  final int cents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EC),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded, color: Color(0xFF15803D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF315B3E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.formatCents(cents),
            style: const TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _InlineEvent extends StatelessWidget {
  const _InlineEvent({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF697789),
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 42, color: const Color(0xFFE0E5EB));
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.foreground,
    required this.background,
  });
  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}

void _openActivity(BuildContext context, DealActivityViewModel activity) {
  final id = activity.targetId;
  if (id == null || id.isEmpty) return;

  switch (activity.target) {
    case DealActivityTarget.none:
      return;
    case DealActivityTarget.inventory:
      context.pushNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': id},
      );
      return;
    case DealActivityTarget.sale:
      context.pushNamed(
        AppRouteNames.transactionDetail,
        pathParameters: {'transactionId': id},
      );
      return;
    case DealActivityTarget.repair:
      context.pushNamed(
        AppRouteNames.repairDetail,
        pathParameters: {'repairId': id},
      );
      return;
    case DealActivityTarget.disposal:
      context.pushNamed(
        AppRouteNames.disposalDetail,
        pathParameters: {'disposalId': id},
      );
      return;
    case DealActivityTarget.deal:
      context.pushNamed(
        AppRouteNames.dealDetail,
        pathParameters: {'dealId': id},
      );
      return;
  }
}

(IconData, Color, Color) _activityVisual(DealActivityIconKind kind) {
  return switch (kind) {
    DealActivityIconKind.sale => (
      Icons.point_of_sale_outlined,
      const Color(0xFFE8F6EC),
      const Color(0xFF15803D),
    ),
    DealActivityIconKind.inventory => (
      Icons.inventory_2_outlined,
      const Color(0xFFEAF2FB),
      const Color(0xFF1174C2),
    ),
    DealActivityIconKind.cash => (
      Icons.attach_money_rounded,
      const Color(0xFFE8F6EC),
      const Color(0xFF15803D),
    ),
    DealActivityIconKind.repair => (
      Icons.build_outlined,
      const Color(0xFFFFF0C2),
      const Color(0xFF8A5A00),
    ),
    DealActivityIconKind.disposal => (
      Icons.delete_outline,
      const Color(0xFFFCE8E8),
      const Color(0xFFC62828),
    ),
    DealActivityIconKind.warranty => (
      Icons.autorenew_rounded,
      const Color(0xFFEAF2FB),
      const Color(0xFF1174C2),
    ),
    DealActivityIconKind.nestedDeal => (
      Icons.link_rounded,
      const Color(0xFFF3E8FF),
      const Color(0xFF6E23B6),
    ),
  };
}

String _date(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}
