import '../models/layout_node.dart';

class CodeGeneratorService {
  /// Task 3: Wraps the dynamically generated layout tree in a standard
  /// StatelessWidget and Scaffold boilerplate.
  static String generateCode(LayoutNode rootNode) {
    // We start the root node at indent level 4 (8 spaces) so it perfectly aligns
    // with the 'child:' property inside the SafeArea below.
    final String layoutTree = rootNode.toDartCode(indentLevel: 4, isRoot: true);

    // .trimLeft() removes the first line's indentation so it sits cleanly next to 'child: '
    return '''
import 'package:flutter/material.dart';

class GeneratedLayout extends StatelessWidget {
  const GeneratedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ${layoutTree.trimLeft()}      ),
    );
  }
}
''';
  }
}
