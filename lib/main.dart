import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/development_config.dart';
import 'core/config/development_sample_data.dart';
import 'features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'features/inventory/presentation/providers/inventory_providers.dart';
import 'features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final inventoryRepository = InMemoryInventoryRepository(
    initialItems: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createInventoryItems()
        : const [],
  );

  final transactionRepository = InMemoryTransactionRepository(
    initialSales: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createSales()
        : const [],
  );

  runApp(
    ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
      child: const HitTheDeckApp(),
    ),
  );
}
