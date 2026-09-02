import '../models/deal.dart';
import '../models/deal_lineage_edge_type.dart';
import '../models/deal_lineage_node.dart';
import '../models/deal_lineage_tree.dart';
import '../models/trade_transaction.dart';
import '../models/warranty_replacement_deal.dart';

abstract final class DealLineageService {
  static DealLineageTree build({
    required Deal deal,
    required List<TradeTransaction> trades,
    required List<WarrantyReplacementDeal> warrantyReplacements,
  }) {
    if (!deal.isValid) {
      throw StateError('The Deal contains invalid relationship information.');
    }

    final lineageIds = deal.effectiveLineageInventoryItemIds.toSet();
    final directChildIds = deal.childInventoryItemIds.toSet();
    final parentByChild = <String, _ParentRelationship>{};

    for (final trade in trades) {
      final outgoing = trade.outgoingInventoryItemIds
          .where(lineageIds.contains)
          .toSet()
          .toList(growable: false);
      final incoming = trade.incomingInventoryItemIds
          .where(lineageIds.contains)
          .toSet()
          .toList(growable: false);

      if (incoming.isEmpty || outgoing.isEmpty) continue;

      if (outgoing.length != 1) {
        throw StateError(
          'Trade ${trade.id ?? '<unsaved>'} has ${outgoing.length} outgoing '
          'Deal-lineage items. Branch attribution requires exactly one.',
        );
      }

      for (final childId in incoming) {
        _setParent(
          parentByChild: parentByChild,
          directChildIds: directChildIds,
          childId: childId,
          relationship: _ParentRelationship(
            parentInventoryItemId: outgoing.single,
            edgeType: DealLineageEdgeType.trade,
          ),
        );
      }
    }

    for (final warranty in warrantyReplacements) {
      if (!lineageIds.contains(warranty.disposedInventoryItemId) ||
          !lineageIds.contains(warranty.replacementInventoryItemId)) {
        continue;
      }

      _setParent(
        parentByChild: parentByChild,
        directChildIds: directChildIds,
        childId: warranty.replacementInventoryItemId,
        relationship: _ParentRelationship(
          parentInventoryItemId: warranty.disposedInventoryItemId,
          edgeType: DealLineageEdgeType.warrantyReplacement,
        ),
      );
    }

    final nodes = <DealLineageNode>[];
    for (final inventoryItemId in deal.effectiveLineageInventoryItemIds) {
      nodes.add(
        _resolveNode(
          inventoryItemId: inventoryItemId,
          directChildIds: directChildIds,
          parentByChild: parentByChild,
          visiting: <String>{},
        ),
      );
    }

    return DealLineageTree(deal: deal, nodes: nodes);
  }

  static DealLineageNode _resolveNode({
    required String inventoryItemId,
    required Set<String> directChildIds,
    required Map<String, _ParentRelationship> parentByChild,
    required Set<String> visiting,
  }) {
    if (directChildIds.contains(inventoryItemId)) {
      return DealLineageNode(
        inventoryItemId: inventoryItemId,
        rootChildInventoryItemId: inventoryItemId,
        depth: 0,
      );
    }

    if (!visiting.add(inventoryItemId)) {
      throw StateError(
        'Deal lineage contains a cycle involving $inventoryItemId.',
      );
    }

    final relationship = parentByChild[inventoryItemId];
    if (relationship == null) {
      throw StateError(
        'Deal lineage item $inventoryItemId is not reachable from a direct '
        'Deal child through Trade or Warranty relationships.',
      );
    }

    final parentNode = _resolveNode(
      inventoryItemId: relationship.parentInventoryItemId,
      directChildIds: directChildIds,
      parentByChild: parentByChild,
      visiting: visiting,
    );
    visiting.remove(inventoryItemId);

    return DealLineageNode(
      inventoryItemId: inventoryItemId,
      rootChildInventoryItemId: parentNode.rootChildInventoryItemId,
      parentInventoryItemId: relationship.parentInventoryItemId,
      edgeTypeFromParent: relationship.edgeType,
      depth: parentNode.depth + 1,
    );
  }

  static void _setParent({
    required Map<String, _ParentRelationship> parentByChild,
    required Set<String> directChildIds,
    required String childId,
    required _ParentRelationship relationship,
  }) {
    if (directChildIds.contains(childId)) {
      throw StateError(
        'Direct Deal child $childId cannot also have a lineage parent.',
      );
    }

    final existing = parentByChild[childId];
    if (existing != null &&
        (existing.parentInventoryItemId != relationship.parentInventoryItemId ||
            existing.edgeType != relationship.edgeType)) {
      throw StateError(
        'Deal lineage item $childId has conflicting parent relationships.',
      );
    }

    parentByChild[childId] = relationship;
  }
}

class _ParentRelationship {
  const _ParentRelationship({
    required this.parentInventoryItemId,
    required this.edgeType,
  });

  final String parentInventoryItemId;
  final DealLineageEdgeType edgeType;
}
