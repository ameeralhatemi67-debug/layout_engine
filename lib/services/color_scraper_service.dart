// lib/services/color_scraper_service.dart

import 'package:layout_engine/data/models/layout_node.dart';
import 'package:layout_engine/data/models/export_models.dart';

class ColorScraperService {
  /// The master dictionary translating our internal strings to hex codes.
  static const Map<String, String> _colorMap = {
    'light_orange': '0xFFFFB74D',
    'blue': '0xFF90CAF9', // Approx Colors.blue.shade200
    'green': '0xFFA5D6A7', // Approx Colors.green.shade200
    'red': '0xFFEF9A9A', // Approx Colors.red.shade200
    'grey': '0xFFEEEEEE', // Approx Colors.grey.shade200
  };

  /// 1. The Pre-Processor: Traverses the tree and collects unique color strings
  static Set<String> scrapeUniqueColors(LayoutNode node) {
    final Set<String> uniqueColors = {};
    _traverseAndScrape(node, uniqueColors);
    return uniqueColors;
  }

  static void _traverseAndScrape(LayoutNode node, Set<String> colors) {
    // Check main background color
    if (node.properties.containsKey('color')) {
      colors.add(node.properties['color'] as String);
    }
    // Check padding color
    if (node.properties.containsKey('padding_color')) {
      colors.add(node.properties['padding_color'] as String);
    }

    // Recurse through children
    for (var child in node.children) {
      _traverseAndScrape(child, colors);
    }
  }

  /// Helper: Converts snake_case (light_orange) to camelCase (lightOrange)
  static String _toCamelCase(String str) {
    List<String> parts = str.split('_');
    if (parts.isEmpty) return str;
    String result = parts[0];
    for (int i = 1; i < parts.length; i++) {
      result += parts[i][0].toUpperCase() + parts[i].substring(1);
    }
    return result;
  }

  /// 2. The File Generator: Outputs the final app_colors.dart ExportFile
  static ExportFile generateColorFile(Set<String> uniqueColors) {
    // Force the inclusion of 'grey' as it is our fallback color for blank containers
    uniqueColors.add('grey');

    StringBuffer code = StringBuffer();
    code.writeln("import 'package:flutter/material.dart';\n");
    code.writeln("class AppColors {");

    for (String colorStr in uniqueColors) {
      final hexStr = _colorMap[colorStr] ?? '0xFFEEEEEE';
      final varName = _toCamelCase(colorStr);
      code.writeln("  static const Color $varName = Color($hexStr);");
    }

    code.writeln("}");

    return ExportFile(
      fileName: 'app_colors.dart',
      description:
          'A centralized design token file containing all unique colors used in your layout canvas.',
      codeContent: code.toString(),
    );
  }
}
