import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/data/services/storage_service.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/layout_controller.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/ui/canvas/canvas_view.dart';
import 'package:layout_engine/ui/windows/create/create_holder.dart';
import 'package:layout_engine/ui/windows/debug/debug_visualizer.dart';
import 'package:layout_engine/ui/windows/export/code_export_window.dart';
import 'package:layout_engine/ui/windows/layer/layer_window.dart';
import 'package:layout_engine/ui/windows/main/main_holder.dart';
import 'package:layout_engine/ui/windows/padding/padding_panel.dart';
import 'package:layout_engine/ui/windows/split/create_split_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  Get.put(LayoutController());
  final winManager = Get.put(WindowManager());

  Get.put(
    BaseWindowInteractions()
      ..setupAsToolbar(length: 280.0)
      ..exactTopSnapX = 16.0
      ..exactBottomSnapX = 16.0
      ..isHidden.value = false,
    tag: 'Main',
  );

  // 🚀 OS REGISTRY: Register all your dynamic windows here!
  // When you build new windows in the future, just add one line here.
  winManager.registerWindow('Layer', const LayerWindow());
  winManager.registerWindow('Split', const CreateSplitWindow());
  winManager.registerWindow('Create', const CreateHolder());
  winManager.registerWindow('Padding', const PaddingPanel());
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
