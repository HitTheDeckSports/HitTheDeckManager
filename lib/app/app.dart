import 'package:flutter/material.dart';

class HitTheDeckApp extends StatelessWidget {
  const HitTheDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hit the Deck Manager',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),

      home: const Scaffold(
        body: Center(
          child: Text(
            'Hit the Deck Manager v0.1',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
