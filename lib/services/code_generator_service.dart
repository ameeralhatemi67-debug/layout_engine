// lib/services/code_generator_service.dart

import 'package:layout_engine/data/models/layout_node.dart';
import 'package:layout_engine/data/models/export_models.dart';
import 'package:layout_engine/services/dart_translation_engine.dart';
import 'package:layout_engine/services/color_scraper_service.dart';

class CodeGeneratorService {
  static ExportPackage generateExportPackage(LayoutNode rootNode) {
    // 1. Scrape unique colors
    final uniqueColors = ColorScraperService.scrapeUniqueColors(rootNode);
    final colorExportFile = ColorScraperService.generateColorFile(uniqueColors);

    // 2. Initialize the collector list with the color file first
    final List<ExportFile> modularFiles = [colorExportFile];

    // 3. Generate the main layout tree.
    // Passing `modularFiles` allows the engine to extract widgets and append them directly to this list!
    final String mainLayoutTree = DartTranslationEngine.generateNodeCode(
      rootNode,
      indentLevel: 4,
      isRoot: true,
      extractedWidgets: modularFiles,
    );

    // ==========================================
    // 4. BUILD THE "QUICK DUMP" MONOLITH
    // ==========================================
    StringBuffer monolithCode = StringBuffer();
    monolithCode.writeln("import 'package:flutter/material.dart';\n");

    // Inject the Color Tokens
    monolithCode.writeln("// --- DESIGN TOKENS ---");
    monolithCode.writeln(
      colorExportFile.codeContent
          .replaceAll("import 'package:flutter/material.dart';", '')
          .trim(),
    );
    monolithCode.writeln("\n");

    // Inject all extracted Custom Widgets (Skipping index 0 since it's the colors)
    if (modularFiles.length > 1) {
      monolithCode.writeln("// --- CUSTOM WIDGETS ---");
      for (int i = 1; i < modularFiles.length; i++) {
        String rawWidget = modularFiles[i].codeContent;
        rawWidget = rawWidget.replaceAll(
          "import 'package:flutter/material.dart';",
          "",
        );
        rawWidget = rawWidget.replaceAll("import 'app_colors.dart';", "");
        monolithCode.writeln(rawWidget.trim());
        monolithCode.writeln("\n");
      }
    }

    // Inject the Main Layout
    monolithCode.writeln('''// --- MAIN LAYOUT ---
class GeneratedLayout extends StatelessWidget {
  const GeneratedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ${mainLayoutTree.trimLeft()}      ),
    );
  }
}''');

    final singleMonolith = ExportFile(
      fileName: 'quick_dump.dart',
      description:
          'A monolithic file containing the entire layout, design tokens, and custom widgets.',
      codeContent: monolithCode.toString(),
    );

    // ==========================================
    // 5. BUILD THE MODULAR MAIN LAYOUT
    // ==========================================
    // Automatically generate import statements for the extracted widget files
    final importedWidgets = modularFiles
        .skip(1)
        .map((f) => "import '${f.fileName}';")
        .join('\n');

    final String modularMainCode =
        '''
import 'package:flutter/material.dart';
import 'app_colors.dart';
$importedWidgets

class GeneratedLayout extends StatelessWidget {
  const GeneratedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ${mainLayoutTree.trimLeft()}      ),
    );
  }
}
''';

    modularFiles.add(
      ExportFile(
        fileName: 'main_layout.dart',
        description: 'The core structural layout tree of your application.',
        codeContent: modularMainCode.trim(),
      ),
    );

    return ExportPackage(
      singleMonolith: singleMonolith,
      modularFiles: modularFiles,
    );
  }
}
