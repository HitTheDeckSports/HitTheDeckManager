import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/shared/presentation/widgets/app_empty_state.dart';
import 'package:hit_the_deck_manager/shared/presentation/widgets/app_error_state.dart';
import 'package:hit_the_deck_manager/shared/presentation/widgets/app_loading_state.dart';

void main() {
  testWidgets('AppLoadingState displays spinner and optional message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoadingState(message: 'Loading inventory...')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading inventory...'), findsOneWidget);
  });

  testWidgets('AppEmptyState displays icon, text, and optional action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No inventory items yet.',
            message: 'Use Buy Inventory to add your first item.',
            action: FilledButton(
              onPressed: () {},
              child: const Text('Add Inventory'),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.text('No inventory items yet.'), findsOneWidget);
    expect(
      find.text('Use Buy Inventory to add your first item.'),
      findsOneWidget,
    );
    expect(find.text('Add Inventory'), findsOneWidget);
  });

  testWidgets('AppErrorState displays details and retry action', (
    WidgetTester tester,
  ) async {
    var retryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Unable to load inventory.',
            details: 'Network unavailable',
            onRetry: () {
              retryPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Unable to load inventory.'), findsOneWidget);
    expect(find.text('Network unavailable'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));

    expect(retryPressed, isTrue);
  });
}
