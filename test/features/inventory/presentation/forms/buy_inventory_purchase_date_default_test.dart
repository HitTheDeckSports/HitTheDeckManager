import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_controller.dart';

void main() {
  test('new inventory form defaults purchase date to today', () {
    final now = DateTime.now();
    final expectedDate = DateTime(now.year, now.month, now.day);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(buyInventoryFormControllerProvider);

    expect(state.purchaseDate, expectedDate);
  });

  test('reset restores purchase date to today', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    controller.setPurchaseDate(DateTime(2020, 1, 2));
    controller.reset();

    final now = DateTime.now();
    final expectedDate = DateTime(now.year, now.month, now.day);
    final state = container.read(buyInventoryFormControllerProvider);

    expect(state.purchaseDate, expectedDate);
  });
}
