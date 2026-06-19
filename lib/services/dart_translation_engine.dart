// lib/services/dart_translation_engine.dart

import 'package:layout_engine/data/models/layout_node.dart';
import 'package:layout_engine/data/models/export_models.dart'; // Needed for ExportFile

class DartTranslationEngine {
  /// Helper: Formats "Submit Button" into "SubmitButton"
  static String _toPascalCase(String text) {
    if (text.isEmpty) return text;
    final words = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .split(' ');
    return words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join('');
  }

  /// Helper: Formats "Submit Button" into "submit_button"
  static String _toSnakeCase(String text) {
    if (text.isEmpty) return text;
    final words = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .split(' ');
    return words.map((word) => word.toLowerCase()).join('_');
  }

  static String _translateAlignment(String? alignmentStr) {
    switch (alignmentStr) {
      case 'top_left':
        return 'Alignment.topLeft';
      case 'top_center':
        return 'Alignment.topCenter';
      case 'top_right':
        return 'Alignment.topRight';
      case 'center_left':
        return 'Alignment.centerLeft';
      case 'center':
        return 'Alignment.center';
      case 'center_right':
        return 'Alignment.centerRight';
      case 'bottom_left':
        return 'Alignment.bottomLeft';
      case 'bottom_center':
        return 'Alignment.bottomCenter';
      case 'bottom_right':
        return 'Alignment.bottomRight';
      default:
        return 'Alignment.center';
    }
  }

  static String _translateColor(String? colorStr) {
    switch (colorStr) {
      case 'light_orange':
        return 'AppColors.lightOrange';
      case 'blue':
        return 'AppColors.blue';
      case 'green':
        return 'AppColors.green';
      case 'red':
        return 'AppColors.red';
      case 'grey':
      default:
        return 'AppColors.grey';
    }
  }

  /// The Recursive Engine (Now equipped with Component Extraction)
  static String generateNodeCode(
    LayoutNode node, {
    int indentLevel = 0,
    bool isRoot = false,
    String? parentType,
    List<ExportFile>? extractedWidgets, // Collector list
    bool skipExtraction = false, // Infinite loop protection
  }) {
    String getIndent(int level) => '  ' * level;

    int currentLevel = indentLevel;
    String prefix = '';
    String suffix = '';

    // 1. Boundary Protection (Expanded vs SizedBox) - Always applies to the PARENT layout
    if (!isRoot) {
      final isLocked = node.properties['is_locked'] == true;

      if (isLocked) {
        final lockedSize = node.properties['locked_size'] as num? ?? 100.0;
        final dimension = parentType == 'RowNode' ? 'width' : 'height';

        prefix += '${getIndent(currentLevel)}SizedBox(\n';
        prefix += '${getIndent(currentLevel + 1)}$dimension: $lockedSize,\n';
        prefix += '${getIndent(currentLevel + 1)}child: ';

        suffix = '\n${getIndent(currentLevel)}),\n' + suffix;
        currentLevel += 1;
      } else {
        final isExpanded = node.properties['is_expanded'] == true;
        final flexValue = isExpanded
            ? (node.properties['expanded_flex'] as int? ?? 1000)
            : (node.properties['flex_value'] as int? ?? 1000);

        prefix += '${getIndent(currentLevel)}Expanded(\n';
        prefix += '${getIndent(currentLevel + 1)}flex: $flexValue,\n';
        prefix += '${getIndent(currentLevel + 1)}child: ';

        suffix = '\n${getIndent(currentLevel)}),\n' + suffix;
        currentLevel += 1;
      }
    }

    // --- TASK 3.2: WIDGET EXTRACTION INTERCEPTOR ---
    // If a user names a layer something custom, we cut it out right here!
    final layerName = node.properties['layer_name'] as String?;
    final isCustomName =
        layerName != null &&
        layerName != 'Placeholder' &&
        !layerName.startsWith('Split');

    if (isCustomName && extractedWidgets != null && !skipExtraction) {
      final widgetName = _toPascalCase(layerName) + 'Widget';
      final fileName = _toSnakeCase(layerName) + '_widget.dart';

      // Re-run the engine internally to build the isolated widget code
      final innerCode = generateNodeCode(
        node,
        indentLevel: 2,
        isRoot:
            true, // Skips the Expanded wrappers we already placed in the parent
        extractedWidgets: extractedWidgets,
        skipExtraction: true, // Prevents an infinite extraction loop
      );

      final fileContent =
          '''
import 'package:flutter/material.dart';
import 'app_colors.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return ${innerCode.trimLeft()}
  }
}
''';
      // Prevent duplicates if the user copied/pasted the same component multiple times
      if (!extractedWidgets.any((f) => f.fileName == fileName)) {
        extractedWidgets.add(
          ExportFile(
            fileName: fileName,
            description:
                'A modular, reusable component extracted from layer: $layerName.',
            codeContent: fileContent,
          ),
        );
      }

      // Instead of continuing, we just drop the const widget call inline!
      prefix += '${getIndent(currentLevel)}const $widgetName(),';
      return prefix + suffix;
    }
    // ------------------------------------------------

    // 2. Padding Mapping
    final padding = node.properties['padding'] as Map<String, dynamic>?;
    if (padding != null) {
      final double t = (padding['top'] as num?)?.toDouble() ?? 0.0;
      final double b = (padding['bottom'] as num?)?.toDouble() ?? 0.0;
      final double l = (padding['left'] as num?)?.toDouble() ?? 0.0;
      final double r = (padding['right'] as num?)?.toDouble() ?? 0.0;

      if (t > 0 || b > 0 || l > 0 || r > 0) {
        prefix += '${getIndent(currentLevel)}Padding(\n';
        prefix +=
            '${getIndent(currentLevel + 1)}padding: const EdgeInsets.only(top: $t, bottom: $b, left: $l, right: $r),\n';
        prefix += '${getIndent(currentLevel + 1)}child: ';
        suffix = '\n${getIndent(currentLevel)}),' + suffix;
        currentLevel += 1;
      }
    }

    // 3. Viewport Mapping (LockEdit wrapper)
    final isLockedForViewport = node.properties['is_locked'] == true;
    if (isLockedForViewport) {
      prefix += '${getIndent(currentLevel)}SingleChildScrollView(\n';
      prefix += '${getIndent(currentLevel + 1)}child: ';
      suffix = '\n${getIndent(currentLevel)}),' + suffix;
      currentLevel += 1;
    }

    // 4. Structural Mapping
    if (node.type == 'RowNode' || node.type == 'ColumnNode') {
      final widgetName = node.type == 'RowNode' ? 'Row' : 'Column';
      prefix += '${getIndent(currentLevel)}$widgetName(\n';
      prefix +=
          '${getIndent(currentLevel + 1)}crossAxisAlignment: CrossAxisAlignment.stretch,\n';
      prefix += '${getIndent(currentLevel + 1)}children: [\n';

      for (var child in node.children) {
        prefix += generateNodeCode(
          child,
          indentLevel: currentLevel + 2,
          isRoot: false,
          parentType: node.type,
          extractedWidgets:
              extractedWidgets, // Pass it down so nested children can be extracted too!
          skipExtraction: false,
        );
      }

      prefix += '${getIndent(currentLevel + 1)}],';
      prefix += '\n${getIndent(currentLevel)})';
    } else {
      // 5. Leaf Node Mapping
      final alignStr = node.properties['alignment'] as String? ?? 'center';
      final colorStr = node.properties['color'] as String? ?? 'grey';
      final safeLayerName = layerName ?? 'Placeholder';

      prefix += '${getIndent(currentLevel)}Container(\n';
      prefix +=
          '${getIndent(currentLevel + 1)}alignment: ${_translateAlignment(alignStr)},\n';
      prefix +=
          '${getIndent(currentLevel + 1)}color: ${_translateColor(colorStr)},\n';
      prefix +=
          '${getIndent(currentLevel + 1)}child: const Text(\'$safeLayerName\'),';
      prefix += '\n${getIndent(currentLevel)})';
    }

    return prefix + suffix;
  }
}
