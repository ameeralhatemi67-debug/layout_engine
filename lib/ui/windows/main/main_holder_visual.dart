import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/layout_controller.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/ui/windows/Settings/settings_page.dart';
import 'package:layout_engine/ui/windows/export/code_export_window.dart';

class MainHolderVisual extends StatelessWidget {
  final bool isHorizontal;
  final bool isOpen;
  final bool canUndo;
  final bool canRedo;
  final bool showCanvasWireframes;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleWireframe;
  final VoidCallback onToggleLayerWindow;
  final VoidCallback onCopyCode;
  final VoidCallback onToggleOpen;
  final VoidCallback onToggleCreateTools;

  const MainHolderVisual({
    super.key,
    required this.isHorizontal,
    required this.canUndo,
    required this.canRedo,
    required this.isOpen,
    required this.showCanvasWireframes,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleWireframe,
    required this.onToggleLayerWindow,
    required this.onCopyCode,
    required this.onToggleOpen, // ADDED
    required this.onToggleCreateTools,
  });

  @override
  Widget build(BuildContext context) {
    // Helper 1: Draws the dividers dynamically
    Widget buildDivider() {
      return Container(
        width: isHorizontal ? 1 : 24,
        height: isHorizontal ? 24 : 1,
        color: Colors.grey.shade300,
        margin: EdgeInsets.symmetric(
          horizontal: isHorizontal ? 8.0 : 0.0,
          vertical: isHorizontal ? 0.0 : 8.0,
        ),
      );
    }

    // Helper 2: Standardizes ALL icons so they are perfectly the same size
    Widget buildIconBtn({
      required Widget icon,
      required VoidCallback? onTap,
      VoidCallback?
      onLongPress, // MainHolder needs this for the Layer Window toggle!
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            alignment: Alignment.center,
            child: icon,
          ),
        ),
      );
    }

    // Helper 3: Generates standard SVG visuals with dynamic colors and sizes
    Widget buildSvg(String asset, Color color, {double size = 24}) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    // 1. The Main Drag / Minimize Handle
    List<Widget> children = [
      buildIconBtn(
        onTap: onToggleOpen,
        tooltip: 'Drag or Minimize',
        icon: RotatedBox(
          quarterTurns: isHorizontal ? 0 : 1,
          child: buildSvg(
            'assets/icons/MainHolder.svg',
            Colors.black87,
            size: 28,
          ),
        ),
      ),
    ];

    // 2. The Expanded Tools
    if (isOpen) {
      children.addAll([
        buildDivider(),

        buildIconBtn(
          icon: buildSvg(
            'assets/icons/Back.svg',
            canUndo ? Colors.black87 : Colors.grey.shade400,
          ),
          onTap: canUndo ? onUndo : null, // FIX: Safe tap mapping
          tooltip: 'Undo',
        ),
        buildIconBtn(
          icon: Transform.flip(
            flipX: true,
            child: buildSvg(
              'assets/icons/Back.svg',
              canRedo ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
          onTap: canRedo ? onRedo : null, // FIX: Safe tap mapping
          tooltip: 'Redo',
        ),

        buildDivider(),

        // Fixed Eye Toggle
        buildIconBtn(
          icon: buildSvg(
            // Use the passed variable here!
            showCanvasWireframes
                ? 'assets/icons/Look_On.svg'
                : 'assets/icons/Look_Off.svg',
            Colors.black87,
          ),
          onTap: onToggleWireframe,
          onLongPress: onToggleLayerWindow,
          tooltip: 'Toggle Wireframes (Hold for Layers)',
        ),

        buildDivider(),

        buildIconBtn(
          icon: buildSvg('assets/icons/CreateHolder.svg', Colors.black87),
          onTap: onToggleCreateTools, // FIX: Logic moved to Smart Parent!
          tooltip: 'Toggle Create Tools',
        ),

        buildDivider(),

        // 🚀 THE NEW SETTINGS TRIGGER
        buildIconBtn(
          icon: buildSvg('assets/icons/settings.svg', Colors.black87),
          onTap: () {
            // Opens the page overlay with a transparent barrier so the blur works
            Get.dialog(const SettingsPage(), barrierColor: Colors.transparent);
          },
          tooltip: 'Workspace Settings',
        ),

        buildDivider(),

        buildIconBtn(
          icon: buildSvg('assets/icons/CopyIcon.svg', Colors.blueAccent),
          onTap: () => Get.find<LayoutController>()
              .copyCodeToClipboard(), // FIX: Used passed callback
          tooltip: 'Copy Code',
          onLongPress: () {
            // 🚀 The true Modal Route fix! Opens entirely above the OS Stack.
            Get.dialog(
              const CodeExportWindow(),
              barrierColor:
                  Colors.transparent, // The widget handles the dimming
              useSafeArea: false,
            );
          },
        ),
      ]);
    }

    // 3. Render
    return Card(
      elevation: 8, // 🚀 UNIFIED
      color: const Color.fromARGB(255, 247, 242, 250), // 🚀 UNIFIED
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Flex(
          direction: isHorizontal ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
