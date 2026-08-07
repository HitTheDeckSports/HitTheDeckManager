import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import '../../domain/repositories/warranty_replacement_deal_repository.dart';

class InMemoryWarrantyReplacementDealRepository
    implements WarrantyReplacementDealRepository {
  InMemoryWarrantyReplacementDealRepository({
    List<WarrantyReplacementDeal> initialDeals = const [],
    Uuid? uuid,
  }) : _deals = [...initialDeals],
       _uuid = uuid ?? const Uuid();

  final List<WarrantyReplacementDeal> _deals;
  final Uuid _uuid;

  final StreamController<List<WarrantyReplacementDeal>> _controller =
      StreamController<List<WarrantyReplacementDeal>>.broadcast();

  @override
  Future<List<WarrantyReplacementDeal>> getDeals() async {
    return List.unmodifiable(_deals);
  }

  @override
  Stream<List<WarrantyReplacementDeal>> watchDeals() async* {
    yield List.unmodifiable(_deals);
    yield* _controller.stream;
  }

  @override
  Future<WarrantyReplacementDeal?> getDeal(String id) async {
    for (final deal in _deals) {
      if (deal.id == id) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<WarrantyReplacementDeal?> getDealForDisposal(
    String disposalTransactionId,
  ) async {
    for (final deal in _deals) {
      if (deal.disposalTransactionId == disposalTransactionId) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<WarrantyReplacementDeal?> getDealForInventoryItem(
    String inventoryItemId,
  ) async {
    for (final deal in _deals) {
      if (deal.disposedInventoryItemId == inventoryItemId ||
          deal.replacementInventoryItemId == inventoryItemId) {
        return deal;
      }
    }

    return null;
  }

  @override
  Future<WarrantyReplacementDeal> createDeal(
    WarrantyReplacementDeal deal,
  ) async {
    if (!deal.isValid) {
      throw const ValidationException(
        'The warranty replacement Deal contains invalid information.',
      );
    }

    if (await getDealForDisposal(deal.disposalTransactionId) != null) {
      throw DuplicateException(
        'Disposal ${deal.disposalTransactionId} already has a warranty replacement Deal.',
      );
    }

    final id = deal.id ?? _uuid.v4();

    if (_deals.any((existing) => existing.id == id)) {
      throw DuplicateException(
        'A warranty replacement Deal with ID $id already exists.',
      );
    }

    final saved = deal.copyWith(id: id);
    _deals.add(saved);
    _notifyChanged();
    return saved;
  }

  @override
  Future<void> deleteDeal(String id) async {
    final originalLength = _deals.length;
    _deals.removeWhere((deal) => deal.id == id);

    if (_deals.length == originalLength) {
      throw NotFoundException(
        'No warranty replacement Deal exists with ID $id.',
      );
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
