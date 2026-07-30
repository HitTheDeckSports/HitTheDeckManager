// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';
import 'package:flutter/material.dart';
import 'package:hit_the_deck_manager/app/app_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';

void main() {
  testWidgets('app loads home screen and navigates between sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(const HitTheDeckApp());
    await tester.pumpAndSettle();

    expect(find.text('Inventory Management'), findsOneWidget);
    expect(find.text('Buy Inventory'), findsOneWidget);
    expect(find.text('Sell Inventory'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
  });
  testWidgets('home action buttons open inventory workflows', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    appRouter.go(AppRoutes.home);

    await tester.pumpWidget(const HitTheDeckApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buy Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Inventory'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sell Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Sell Inventory'), findsOneWidget);
  });
}
