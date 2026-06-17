import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';

class DebugSnapZonesOverlay extends StatelessWidget {
  const DebugSnapZonesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BaseWindowInteractions>(tag: 'Main')) {
      return const SizedBox.shrink();
    }
    final logic = Get.find<BaseWindowInteractions>(tag: 'Main');

    return Obx(() {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      final safeBottom = MediaQuery.of(context).size.height - bottomPadding;
      final screenW = MediaQuery.of(context).size.width;

      final dZone = logic.detectDistance.value;

      List<Widget> visuals = [];

      // =====================================================================
      // 1. TRIANGLE TOGGLE: The Rounded Snapping Destination Lines
      // =====================================================================
      if (logic.showDebugSnap.value) {
        Widget snapLine(double? w, double? h, Color color) {
          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10), // Rounded ends
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }

        final double lineThickness = 6.0;

        visuals.addAll([
          // 🚀 Uses individual topPadding
          Positioned(
            top: logic.topPadding.value,
            left: (screenW / 2) - (logic.topLength.value / 2),
            child: snapLine(
              logic.topLength.value,
              lineThickness,
              Colors.lightGreenAccent,
            ),
          ),
          // 🚀 Uses individual bottomPadding
          Positioned(
            bottom: bottomPadding + logic.bottomPadding.value,
            left: (screenW / 2) - (logic.bottomLength.value / 2),
            child: snapLine(
              logic.bottomLength.value,
              lineThickness,
              Colors.lightGreenAccent,
            ),
          ),
          // 🚀 Uses individual leftPadding
          Positioned(
            left: logic.leftPadding.value,
            top: (safeBottom / 2) - (logic.leftLength.value / 2),
            child: snapLine(
              lineThickness,
              logic.leftLength.value,
              Colors.redAccent,
            ),
          ),
          // 🚀 Uses individual rightPadding
          Positioned(
            right: logic.rightPadding.value,
            top: (safeBottom / 2) - (logic.rightLength.value / 2),
            child: snapLine(
              lineThickness,
              logic.rightLength.value,
              Colors.redAccent,
            ),
          ),
        ]);
      }

      // =====================================================================
      // 2. SQUARE TOGGLE: The Asymmetric Detection Zones
      // =====================================================================
      if (logic.showDetectionZones.value) {
        Widget stripedBar(double? w, double? h) {
          return Container(
            width: w,
            height: h,
            decoration: const BoxDecoration(
              gradient: RepeatingLinearGradient(
                colors: [Colors.transparent, Colors.black12],
                stops: [0.0, 0.5],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        }

        visuals.addAll([
          // 🚀 Uses the global dZone for all 4 sides!
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: dZone,
              color: Colors.cyanAccent.withOpacity(0.2),
              child: stripedBar(null, dZone),
            ),
          ),
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            child: Container(
              height: dZone,
              color: Colors.cyanAccent.withOpacity(0.2),
              child: stripedBar(null, dZone),
            ),
          ),
          Positioned(
            top: 0,
            bottom: bottomPadding,
            left: 0,
            child: Container(
              width: dZone,
              color: Colors.cyanAccent.withOpacity(0.2),
              child: stripedBar(dZone, null),
            ),
          ),
          Positioned(
            top: 0,
            bottom: bottomPadding,
            right: 0,
            child: Container(
              width: dZone,
              color: Colors.cyanAccent.withOpacity(0.2),
              child: stripedBar(dZone, null),
            ),
          ),
        ]);
      }

      if (visuals.isEmpty) return const SizedBox.shrink();
      return IgnorePointer(child: Stack(children: visuals));
    });
  }
}

class RepeatingLinearGradient extends LinearGradient {
  const RepeatingLinearGradient({
    required super.colors,
    required super.stops,
    super.begin,
    super.end,
  });
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    return super.createShader(
      const Rect.fromLTWH(0, 0, 20, 20),
      textDirection: textDirection,
    );
  }
}
