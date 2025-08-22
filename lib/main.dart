import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // make sure Firebase is ready
  runApp(const FinGenAIApp());
}

class FinGenAIApp extends StatelessWidget {
  const FinGenAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinGenAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const SplashScreen(),
    );
  }
}
