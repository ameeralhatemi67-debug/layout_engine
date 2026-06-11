import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'package:layout_engine/controllers/window_manager.dart';

import 'package:layout_engine/views/overlays/create_holder.dart';
import 'package:layout_engine/views/overlays/main_holder.dart';
import 'package:layout_engine/views/overlays/create_split_window.dart';
import 'views/overlays/layer_window.dart';
import 'controllers/layout_controller.dart';
import 'services/storage_service.dart';

import 'views/canvas/canvas_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Instantiate the controllers here
  Get.put(LayoutController());
  final winManager = Get.put(WindowManager());

  // 🚀 OS REGISTRY: Register all your dynamic windows here!
  // When you build new windows in the future, just add one line here.
  winManager.registerWindow('Layer', const LayerWindow());
  winManager.registerWindow('Split', const CreateSplitWindow());
  winManager.registerWindow('Create', const CreateHolder());
  winManager.registerWindow('Main', const MainHolder());

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
          // FIX: Wrapping the MAIN Stack in Obx fixes the 0x0 dimension crash!
          child: Obx(() {
            final winManager = Get.find<WindowManager>();
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. The rendered workspace (Bottom Layer - Gives the Stack its full screen size!)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CanvasView(),
                ),

                // 2. The Visual Debugger Layer
                const DebugSnapZonesOverlay(),

                // 3. Dynamic Windows injected straight into the master stack in perfect Z-Order!
                ...winManager.orderedWindows,
              ],
            );
          }),
        ),
      ),
    );
  }
}
