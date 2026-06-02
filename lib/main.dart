import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/storage_service.dart';

void main() async {
  // Required because we are calling async functions before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Offline-First Storage
  await StorageService.init();

  runApp(const LayoutEngineApp());
}

class LayoutEngineApp extends StatelessWidget {
  const LayoutEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use GetMaterialApp instead of MaterialApp to enable context-free routing
    // and reactive state management for the overlays later.
    return GetMaterialApp(
      title: 'Layout Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.grey[100]),
      home: const Scaffold(
        body: Center(child: Text('Layout Engine Database Initialized')),
      ),
    );
  }
}
