import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/views/overlays/create_holder.dart';
import 'package:layout_engine/views/overlays/main_holder.dart';
import 'controllers/layout_controller.dart';
import 'services/storage_service.dart';
import 'views/canvas/canvas_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Instantiate the controller here so it is available globally
  Get.put(LayoutController());

  runApp(const LayoutEngineApp());
}

class LayoutEngineApp extends StatelessWidget {
  const LayoutEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Layout Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.grey[200]),
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // 1. The rendered workspace (Bottom Layer)
              const Padding(padding: EdgeInsets.all(16.0), child: CanvasView()),

              // 2. The MainHolder (Top Center)
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: MainHolder(),
                ),
              ),

              // 3. The CreateHolder (Bottom Center)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: CreateHolder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
