import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Needed before calling any plugin code (like Firebase) in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Connects the app to your Firebase project using firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope stores the state for all Riverpod providers.
  runApp(const ProviderScope(child: CampusReportApp()));
}

class CampusReportApp extends StatelessWidget {
  const CampusReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Report',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F4A6D),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Firebase connected ✅')),
      ),
    );
  }
}