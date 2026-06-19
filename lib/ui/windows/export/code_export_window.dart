// lib/ui/windows/export/code_export_window.dart

import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:layout_engine/data/models/export_models.dart';
import 'package:layout_engine/logic/layout_controller.dart';
import 'package:layout_engine/services/code_generator_service.dart';
import 'package:layout_engine/services/error_handling.dart';

class CodeExportWindow extends StatelessWidget {
  const CodeExportWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final layoutController = Get.find<LayoutController>();
    final exportPackage = CodeGeneratorService.generateExportPackage(
      layoutController.activeLayout,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dimmed & Blurred Background (Exactly from settings.dart)
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

          // 2. The Adaptive, Scrollable Window (Exactly from settings.dart)
          Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF9F9F9,
                ), // 🚀 Your custom export main color
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- WINDOW HEADER ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: const Text(
                      'Production Export',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A), // 🚀 Requested Text Color
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  // --- SCROLLABLE FILE LIST ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      itemCount: exportPackage.modularFiles.length,
                      itemBuilder: (context, index) {
                        final file = exportPackage.modularFiles[index];
                        return _buildFileBlock(file);
                      },
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

  Widget _buildFileBlock(ExportFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Text
          Text(
            file.description,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Header: File Name & Copy Button
          _EditableFileHeader(file: file),
          const SizedBox(height: 8),

          // --- CODE VIEWER CONTAINER ---
          Container(
            height: 320,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(
                0xFF343434,
              ), // 🚀 Requested Code Container Color
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                file.codeContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFF2F2F2), // 🚀 Requested Code Text Color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// The Interactive Double-Tap Header
// -------------------------------------------------------------
class _EditableFileHeader extends StatefulWidget {
  final ExportFile file;

  const _EditableFileHeader({required this.file});

  @override
  State<_EditableFileHeader> createState() => _EditableFileHeaderState();
}

class _EditableFileHeaderState extends State<_EditableFileHeader> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.file.fileName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveName() {
    setState(() {
      widget.file.fileName = _controller.text.trim();
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: isEditing
              ? TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A), // 🚀 Requested Text Color
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  onSubmitted: (_) => _saveName(),
                  onEditingComplete: _saveName,
                  onTapOutside: (_) => _saveName(),
                )
              : GestureDetector(
                  onDoubleTap: () => setState(() => isEditing = true),
                  child: Text(
                    widget.file.fileName,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A), // 🚀 Requested Text Color
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),

        // Action Buttons
        Row(
          children: [
            if (isEditing)
              GestureDetector(
                onTap: _saveName,
                child: const Icon(
                  Icons.check_circle,
                  size: 22,
                  color: Colors.green,
                ),
              ),
            if (!isEditing) ...[
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.file.codeContent),
                  );
                  ErrorHandler.showSuccess(
                    'Copied!',
                    '${widget.file.fileName} copied to clipboard.',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 16, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text(
                        "Copy",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
