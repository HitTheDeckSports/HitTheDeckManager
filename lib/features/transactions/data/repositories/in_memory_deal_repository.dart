import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/deal.dart';
import '../../domain/repositories/deal_repository.dart';

class InMemoryDealRepository implements DealRepository {
  InMemoryDealRepository({List<Deal> initialDeals = const [], Uuid? uuid})
    : _deals = [...initialDeals],
      _uuid = uuid ?? const Uuid();

  final List<Deal> _deals;
  final Uuid _uuid;

  final StreamController<List<Deal>> _controller =
      StreamController<List<Deal>>.broadcast();

  @override
  Future<List<Deal>> getDeals() async {
    return List.unmodifiable(_deals);
  }

  @override
  Stream<List<Deal>> watchDeals() async* {
    yield List.unmodifiable(_deals);
    yield* _controller.stream;
  }

  @override
  Future<Deal?> getDeal(String id) async {
    for (final deal in _deals) {
      if (deal.id == id) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<Deal?> getDealForParentSale(String saleTransactionId) async {
    for (final deal in _deals) {
      if (deal.parentSaleTransactionId == saleTransactionId) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<Deal?> getDealForChildInventoryItem(String inventoryItemId) async {
    for (final deal in _deals) {
      if (deal.childInventoryItemIds.contains(inventoryItemId)) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    if (!deal.isValid) {
      throw const ValidationException(
        'The Deal contains invalid relationship information.',
      );
    }

    if (await getDealForParentSale(deal.parentSaleTransactionId) != null) {
      throw DuplicateException(
        'Sale ${deal.parentSaleTransactionId} already has a Deal.',
      );
    }

    for (final childId in deal.childInventoryItemIds) {
      if (await getDealForChildInventoryItem(childId) != null) {
        throw DuplicateException(
          'Inventory item $childId already belongs to another Deal.',
        );
      }
    }

    final id = deal.id ?? _uuid.v4();

    if (_deals.any((existing) => existing.id == id)) {
      throw DuplicateException('A Deal with ID $id already exists.');
    }

    final savedDeal = deal.copyWith(id: id);
    _deals.add(savedDeal);
    _notifyChanged();

    return savedDeal;
  }

  @override
  Future<Deal> updateDeal(Deal deal) async {
    final id = deal.id;

    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A Deal must have an ID before it can be updated.',
      );
    }

    if (!deal.isValid) {
      throw const ValidationException(
        'The Deal contains invalid relationship information.',
      );
    }

    final index = _deals.indexWhere((existing) => existing.id == id);

    if (index == -1) {
      throw NotFoundException('No Deal exists with ID $id.');
    }

    final parentConflict = _deals.any(
      (existing) =>
          existing.id != id &&
          existing.parentSaleTransactionId == deal.parentSaleTransactionId,
    );

    if (parentConflict) {
      throw DuplicateException(
        'Sale ${deal.parentSaleTransactionId} already has a Deal.',
      );
    }

    for (final childId in deal.childInventoryItemIds) {
      final childConflict = _deals.any(
        (existing) =>
            existing.id != id &&
            existing.childInventoryItemIds.contains(childId),
      );

      if (childConflict) {
        throw DuplicateException(
          'Inventory item $childId already belongs to another Deal.',
        );
      }
    }

    _deals[index] = deal;
    _notifyChanged();

    return deal;
  }

  @override
  Future<void> deleteDeal(String id) async {
    final originalLength = _deals.length;
    _deals.removeWhere((deal) => deal.id == id);

    if (_deals.length == originalLength) {
      throw NotFoundException('No Deal exists with ID $id.');
    }

    _notifyChanged();
  }

  void _notifyChanged() {
    _controller.add(List.unmodifiable(_deals));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
