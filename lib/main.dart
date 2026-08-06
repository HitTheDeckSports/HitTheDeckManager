import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/development_config.dart';
import 'core/config/development_sample_data.dart';
import 'features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'features/contacts/presentation/providers/contact_providers.dart';
import 'features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'features/inventory/presentation/providers/inventory_providers.dart';
import 'features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final contactRepository = InMemoryContactRepository(
    initialContacts: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createContacts()
        : const [],
  );

  final inventoryRepository = InMemoryInventoryRepository(
    initialItems: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createInventoryItems()
        : const [],
  );

  final transactionRepository = InMemoryTransactionRepository(
    initialSales: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createSales()
        : const [],
    initialRepairs: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createRepairs()
        : const [],
    initialTrades: DevelopmentConfig.useSampleData
        ? DevelopmentSampleData.createTrades()
        : const [],
  );

  runApp(
    ProviderScope(
      overrides: [
        contactRepositoryProvider.overrideWithValue(contactRepository),
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
      child: const HitTheDeckApp(),
    ),
  );
}
