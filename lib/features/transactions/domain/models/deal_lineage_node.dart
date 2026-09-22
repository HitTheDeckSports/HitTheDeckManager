import 'deal_lineage_edge_type.dart';

class DealLineageNode {
  const DealLineageNode({
    required this.inventoryItemId,
    required this.rootChildInventoryItemId,
    required this.depth,
    this.parentInventoryItemId,
    this.edgeTypeFromParent,
  });

  final String inventoryItemId;
  final String rootChildInventoryItemId;
  final String? parentInventoryItemId;
  final DealLineageEdgeType? edgeTypeFromParent;
  final int depth;

  bool get isDirectChild => parentInventoryItemId == null;
}
