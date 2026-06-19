import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/ui/windows/Settings/detection_snapping_panel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Accordion toggle states
  bool _isDetectionOpen = true;
  bool _isAnotherSetting1Open = false;

  // Local Draft States for the UI
  late double draftDetect;
  late Map<String, Map<String, double>> draftMatrix;

  // Original States (To check if the user actually made changes)
  late double originalDetect;
  late Map<String, Map<String, double>> originalMatrix;

  @override
  void initState() {
    super.initState();
    final logic = Get.find<BaseWindowInteractions>(tag: 'Main');

    // 1. Pull the initial detection distance
    originalDetect = logic.detectDistance.value;
    draftDetect = originalDetect;

    // 2. Construct the dense 5x5 data matrix from the global logic
    draftMatrix = {
      'L': {
        'ED': logic.leftPadding.value,
        'LW': logic.leftLength.value,
        'LP': logic.leftPosition.value,
      },
      'R': {
        'ED': logic.rightPadding.value,
        'LW': logic.rightLength.value,
        'LP': logic.rightPosition.value,
      },
      'U': {
        'ED': logic.topPadding.value,
        'LW': logic.topLength.value,
        'LP': logic.topPosition.value,
      },
      'D': {
        'ED': logic.bottomPadding.value,
        'LW': logic.bottomLength.value,
        'LP': logic.bottomPosition.value,
      },
    };

    // 3. Create a deep copy for the original matrix to compare against later
    originalMatrix = {
      for (var entry in draftMatrix.entries)
        entry.key: Map<String, double>.from(entry.value),
    };
  }

  // 🚀 This dynamically calculates if the save button should light up!
  bool get isDirtyState {
    if (draftDetect != originalDetect) return true;
    for (String edge in ['L', 'R', 'U', 'D']) {
      for (String attr in ['ED', 'LW', 'LP']) {
        if (draftMatrix[edge]![attr] != originalMatrix[edge]![attr])
          return true;
      }
    }
    return false;
  }

  void _saveSettings() {
    final logic = Get.find<BaseWindowInteractions>(tag: 'Main');

    // Save Detection
    logic.detectDistance.value = draftDetect;

    // Save Matrix Left/Right
    logic.leftPadding.value = draftMatrix['L']!['ED']!;
    logic.leftLength.value = draftMatrix['L']!['LW']!;
    logic.leftPosition.value = draftMatrix['L']!['LP']!;

    logic.rightPadding.value = draftMatrix['R']!['ED']!;
    logic.rightLength.value = draftMatrix['R']!['LW']!;
    logic.rightPosition.value = draftMatrix['R']!['LP']!;

    // Save Matrix Up/Down
    logic.topPadding.value = draftMatrix['U']!['ED']!;
    logic.topLength.value = draftMatrix['U']!['LW']!;
    logic.topPosition.value = draftMatrix['U']!['LP']!;

    logic.bottomPadding.value = draftMatrix['D']!['ED']!;
    logic.bottomLength.value = draftMatrix['D']!['LW']!;
    logic.bottomPosition.value = draftMatrix['D']!['LP']!;

    Get.back();
    Get.snackbar(
      'Settings Saved',
      'Workspace physics updated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.greenAccent.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Dimmed & Blurred Background
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),

          // 2. The Adaptive, Scrollable Window
          Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
              decoration: BoxDecoration(
                // 🚀 UI FIX: The sleek dark background from your mockup
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(
                  8,
                ), // Tighter Figma-style corners
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45, // Darker shadow
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER ---
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Workspace Physics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            Colors.white, // 🚀 UI FIX: White text for dark mode
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Colors.white24,
                  ), // 🚀 UI FIX: Darker divider
                  // --- SCROLLABLE BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          CollapsibleSection(
                            title: 'Detection & Snapping',
                            isOpen: _isDetectionOpen,
                            onToggle: () => setState(
                              () => _isDetectionOpen = !_isDetectionOpen,
                            ),
                            child: DetectionSnappingPanel(
                              draftDetect: draftDetect,
                              draftMatrix: draftMatrix,
                              onDetectChanged: (val) =>
                                  setState(() => draftDetect = val),
                              onMatrixChanged: (edge, attr, val) => setState(
                                () => draftMatrix[edge]![attr] = val,
                              ),
                            ),
                          ),

                          CollapsibleSection(
                            title: 'Another Setting',
                            isOpen: _isAnotherSetting1Open,
                            onToggle: () => setState(
                              () => _isAnotherSetting1Open =
                                  !_isAnotherSetting1Open,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Placeholder...',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- FOOTER ---
                  const Divider(
                    height: 1,
                    color: Colors.white24,
                  ), // 🚀 UI FIX: Darker divider
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment
                          .centerRight, // 🚀 UI FIX: Moved save button to bottom right like Figma
                      child: FloatingActionButton.small(
                        onPressed: isDirtyState ? _saveSettings : null,
                        backgroundColor: isDirtyState
                            ? Colors
                                  .white // 🚀 UI FIX: High-contrast white button when active
                            : Colors.white24,
                        elevation: isDirtyState ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.save,
                          color: isDirtyState
                              ? Colors.black87
                              : Colors.white54, // Dark icon on white button
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPER: Groups settings into clean sections
  // =========================================================
  Widget _buildSection(String title, List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  // =========================================================
  // HELPER: The Drag-to-Edit Field
  // =========================================================
  Widget _buildDragField(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🚀 THE OVERFLOW FIX: Wrapped the text in an Expanded widget
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow
                  .ellipsis, // Fades text instead of crashing if screen is ultra-narrow
            ),
          ),
          const SizedBox(width: 8), // Tiny spacer between text and box
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              double newVal = value + (details.delta.dx * 0.5);
              if (newVal < 0) newVal = 0;
              if (newVal > 400) newVal = 400;
              onChanged(newVal);
            },
            child: Container(
              width: 80, // Fixed width for the number box
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    size: 14,
                    color: Colors.grey,
                  ),
                  Text(
                    value.round().toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniZone({double? width, double? height, required Color color}) {
    return Container(
      width: width,
      height: height,
      color: color.withOpacity(0.3),
    );
  }
}

// 🚀 Task 2.1: The Reusable Animated Accordion Component
class CollapsibleSection extends StatelessWidget {
  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Figma-style rotating triangle
                AnimatedRotation(
                  turns: isOpen ? 0.25 : 0.0, // Rotates 90 degrees down
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white70,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Smooth opening animation
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isOpen ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
