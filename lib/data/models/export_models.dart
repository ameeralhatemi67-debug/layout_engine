// lib/data/models/export_models.dart

class ExportFile {
  /// The name of the file (e.g., 'main_layout.dart').
  /// This is mutable (not final) so the user can rename it in the UI later.
  String fileName;

  /// A brief description of what this file contains, shown above the code block.
  final String description;

  /// The actual generated Dart code string.
  final String codeContent;

  ExportFile({
    required this.fileName,
    required this.description,
    required this.codeContent,
  });
}

class ExportPackage {
  /// The "Quick Dump" file containing everything in one massive monolithic script.
  /// Used for the single-tap copy action.
  final ExportFile singleMonolith;

  /// The cleanly separated files (e.g., app_colors.dart, main_layout.dart, etc.).
  /// Used for the long-press Code Export Window.
  final List<ExportFile> modularFiles;

  ExportPackage({required this.singleMonolith, required this.modularFiles});
}
