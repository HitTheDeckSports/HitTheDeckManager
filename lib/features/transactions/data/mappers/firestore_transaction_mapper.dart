import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/consignment_transaction.dart';
import '../../domain/models/disposal_reason.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/repair_transaction.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/trade_transaction.dart';
import '../../domain/models/transaction_enums.dart';

abstract final class FirestoreTransactionMapper {
  static Map<String, Object?> saleToFirestore(
    SaleTransaction transaction, {
    bool includeCreatedAt = false,
  }) {
    return {
      'inventoryItemId': transaction.inventoryItemId,
      'salePriceCents': transaction.salePriceCents,
      'saleDate': Timestamp.fromDate(transaction.saleDate),
      'paymentMethod': transaction.paymentMethod.name,
      'buyerContactId': _emptyToNull(transaction.buyerContactId),
      'notes': _emptyToNull(transaction.notes),
      'acquisitionValueCents': transaction.acquisitionValueCents,
      'tradeInCreditCents': transaction.tradeInCreditCents,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SaleTransaction saleFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _data(document);

    return SaleTransaction(
      id: document.id,
      inventoryItemId: _requiredString(
        data['inventoryItemId'],
        'inventoryItemId',
      ),
      salePriceCents: _requiredInt(data['salePriceCents'], 'salePriceCents'),
      saleDate: _requiredDate(data['saleDate'], 'saleDate'),
      paymentMethod: _enumValue(
        data['paymentMethod'],
        PaymentMethod.values,
        'paymentMethod',
      ),
      buyerContactId: _stringOrNull(data['buyerContactId']),
      notes: _stringOrNull(data['notes']),
      acquisitionValueCents: _intOrNull(data['acquisitionValueCents']),
      tradeInCreditCents: _intOrNull(data['tradeInCreditCents']) ?? 0,
    );
  }

  static Map<String, Object?> repairToFirestore(
    RepairTransaction transaction, {
    bool includeCreatedAt = false,
  }) {
    return {
      'inventoryItemId': transaction.inventoryItemId,
      'repairDate': Timestamp.fromDate(transaction.repairDate),
      'costCents': transaction.costCents,
      'description': transaction.description.trim(),
      'notes': _emptyToNull(transaction.notes),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static RepairTransaction repairFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _data(document);

    return RepairTransaction(
      id: document.id,
      inventoryItemId: _requiredString(
        data['inventoryItemId'],
        'inventoryItemId',
      ),
      repairDate: _requiredDate(data['repairDate'], 'repairDate'),
      costCents: _requiredInt(data['costCents'], 'costCents'),
      description: _requiredString(data['description'], 'description'),
      notes: _stringOrNull(data['notes']),
    );
  }

  static Map<String, Object?> consignmentToFirestore(
    ConsignmentTransaction transaction, {
    bool includeCreatedAt = false,
  }) {
    return {
      'inventoryItemId': transaction.inventoryItemId,
      'consignmentDate': Timestamp.fromDate(transaction.consignmentDate),
      'commissionCents': transaction.commissionCents,
      'consignorContactId': _emptyToNull(transaction.consignorContactId),
      'saleTransactionId': _emptyToNull(transaction.saleTransactionId),
      'notes': _emptyToNull(transaction.notes),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ConsignmentTransaction consignmentFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _data(document);

    return ConsignmentTransaction(
      id: document.id,
      inventoryItemId: _requiredString(
        data['inventoryItemId'],
        'inventoryItemId',
      ),
      consignmentDate: _requiredDate(
        data['consignmentDate'],
        'consignmentDate',
      ),
      commissionCents: _requiredInt(data['commissionCents'], 'commissionCents'),
      consignorContactId: _stringOrNull(data['consignorContactId']),
      saleTransactionId: _stringOrNull(data['saleTransactionId']),
      notes: _stringOrNull(data['notes']),
    );
  }

  static Map<String, Object?> disposalToFirestore(
    DisposalTransaction transaction, {
    bool includeCreatedAt = false,
  }) {
    return {
      'inventoryItemId': transaction.inventoryItemId,
      'disposalDate': Timestamp.fromDate(transaction.disposalDate),
      'reason': transaction.reason.name,
      'notes': _emptyToNull(transaction.notes),
      'replacementInventoryItemId': _emptyToNull(
        transaction.replacementInventoryItemId,
      ),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DisposalTransaction disposalFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _data(document);

    return DisposalTransaction(
      id: document.id,
      inventoryItemId: _requiredString(
        data['inventoryItemId'],
        'inventoryItemId',
      ),
      disposalDate: _requiredDate(data['disposalDate'], 'disposalDate'),
      reason: _enumValue(data['reason'], DisposalReason.values, 'reason'),
      notes: _stringOrNull(data['notes']),
      replacementInventoryItemId: _stringOrNull(
        data['replacementInventoryItemId'],
      ),
    );
  }

  static Map<String, Object?> tradeToFirestore(
    TradeTransaction transaction, {
    bool includeCreatedAt = false,
  }) {
    return {
      'saleTransactionId': _emptyToNull(transaction.saleTransactionId),
      'outgoingInventoryItemIds': transaction.outgoingInventoryItemIds,
      'incomingInventoryItemIds': transaction.incomingInventoryItemIds,
      'tradeDate': Timestamp.fromDate(transaction.tradeDate),
      'contactId': _emptyToNull(transaction.contactId),
      'cashPaidCents': transaction.cashPaidCents,
      'cashReceivedCents': transaction.cashReceivedCents,
      'paymentMethod': transaction.paymentMethod?.name,
      'notes': _emptyToNull(transaction.notes),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static TradeTransaction tradeFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _data(document);

    return TradeTransaction(
      id: document.id,
      saleTransactionId: _stringOrNull(data['saleTransactionId']),
      outgoingInventoryItemIds: _stringList(data['outgoingInventoryItemIds']),
      incomingInventoryItemIds: _stringList(data['incomingInventoryItemIds']),
      tradeDate: _requiredDate(data['tradeDate'], 'tradeDate'),
      contactId: _stringOrNull(data['contactId']),
      cashPaidCents: _intOrNull(data['cashPaidCents']) ?? 0,
      cashReceivedCents: _intOrNull(data['cashReceivedCents']) ?? 0,
      paymentMethod: _nullableEnumValue(
        data['paymentMethod'],
        PaymentMethod.values,
      ),
      notes: _stringOrNull(data['notes']),
    );
  }

  static Map<String, dynamic> _data(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Transaction document ${document.id} does not contain data.',
      );
    }

    return data;
  }

  static String _requiredString(Object? value, String fieldName) {
    final result = _stringOrNull(value);

    if (result == null) {
      throw StateError('Transaction field $fieldName is missing or invalid.');
    }

    return result;
  }

  static int _requiredInt(Object? value, String fieldName) {
    final result = _intOrNull(value);

    if (result == null) {
      throw StateError('Transaction field $fieldName is missing or invalid.');
    }

    return result;
  }

  static DateTime _requiredDate(Object? value, String fieldName) {
    final result = switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    };

    if (result == null) {
      throw StateError('Transaction field $fieldName is missing or invalid.');
    }

    return result;
  }

  static T _enumValue<T extends Enum>(
    Object? rawValue,
    List<T> values,
    String fieldName,
  ) {
    final result = _nullableEnumValue(rawValue, values);

    if (result == null) {
      throw StateError('Transaction field $fieldName is missing or invalid.');
    }

    return result;
  }

  static T? _nullableEnumValue<T extends Enum>(
    Object? rawValue,
    List<T> values,
  ) {
    final name = _stringOrNull(rawValue);

    if (name == null) {
      return null;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return null;
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intOrNull(Object? value) {
    return switch (value) {
      int intValue => intValue,
      num numberValue => numberValue.toInt(),
      _ => null,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return List<String>.unmodifiable(
      value
          .whereType<String>()
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty),
    );
  }
}
