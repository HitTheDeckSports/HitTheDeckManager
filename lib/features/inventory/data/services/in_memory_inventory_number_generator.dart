import '../../domain/models/inventory_enums.dart';
import '../../domain/services/inventory_number_generator.dart';

class InMemoryInventoryNumberGenerator implements InventoryNumberGenerator {
  final Map<String, int> _sequences = {};

  @override
  Future<String> generate({
    required InventoryCategory category,
    required DateTime date,
  }) async {
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final sequenceKey = '${category.prefix}-$year$month';

    final nextSequence = (_sequences[sequenceKey] ?? 0) + 1;
    _sequences[sequenceKey] = nextSequence;

    final formattedSequence = nextSequence.toString().padLeft(4, '0');

    return '$sequenceKey-$formattedSequence';
  }
}
