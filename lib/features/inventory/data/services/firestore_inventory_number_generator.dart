import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/inventory_enums.dart';

class FirestoreInventoryNumberGenerator {
  const FirestoreInventoryNumberGenerator();

  static const String counterCollectionName = 'inventory_number_counters';

  String counterDocumentId({
    required InventoryCategory category,
    required DateTime date,
  }) {
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '${category.prefix}-$year$month';
  }

  String inventoryNumber({
    required InventoryCategory category,
    required DateTime date,
    required int sequence,
  }) {
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final sequenceText = sequence.toString().padLeft(4, '0');

    return '${category.prefix}-$year$month-$sequenceText';
  }

  Future<String> generateInTransaction({
    required FirebaseFirestore firestore,
    required Transaction transaction,
    required InventoryCategory category,
    required DateTime date,
  }) async {
    final counterId = counterDocumentId(category: category, date: date);

    final counterReference = firestore
        .collection(counterCollectionName)
        .doc(counterId);

    final counterSnapshot = await transaction.get(counterReference);

    final currentSequence = counterSnapshot.exists
        ? _sequenceFromSnapshot(counterSnapshot)
        : 0;

    final nextSequence = currentSequence + 1;

    transaction.set(counterReference, {
      'category': category.name,
      'period': counterId,
      'lastSequence': nextSequence,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return inventoryNumber(
      category: category,
      date: date,
      sequence: nextSequence,
    );
  }

  int _sequenceFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final value = snapshot.data()?['lastSequence'];

    return switch (value) {
      int intValue => intValue,
      num numberValue => numberValue.toInt(),
      _ => 0,
    };
  }
}
