import 'deal.dart';
import 'deal_lineage_node.dart';

class DealLineageTree {
  DealLineageTree({required this.deal, required List<DealLineageNode> nodes})
    : nodes = List.unmodifiable(nodes),
      _nodeByInventoryId = {
        for (final node in nodes) node.inventoryItemId: node,
      };

  final Deal deal;
  final List<DealLineageNode> nodes;
  final Map<String, DealLineageNode> _nodeByInventoryId;

  DealLineageNode? nodeFor(String inventoryItemId) =>
      _nodeByInventoryId[inventoryItemId];

  List<DealLineageNode> get directChildren =>
      nodes.where((node) => node.isDirectChild).toList(growable: false);

  List<DealLineageNode> childrenOf(String inventoryItemId) => nodes
      .where((node) => node.parentInventoryItemId == inventoryItemId)
      .toList(growable: false);

  List<DealLineageNode> branchFor(String rootChildInventoryItemId) => nodes
      .where(
        (node) => node.rootChildInventoryItemId == rootChildInventoryItemId,
      )
      .toList(growable: false);
}
