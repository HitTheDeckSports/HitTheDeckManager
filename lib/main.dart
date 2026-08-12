import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'features/transactions/presentation/providers/deal_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final dealRepository = InMemoryDealRepository(initialDeals: const []);

  runApp(
    ProviderScope(
      overrides: [dealRepositoryProvider.overrideWithValue(dealRepository)],
      child: const HitTheDeckApp(),
    ),
  );
}
