import 'package:uuid/uuid.dart';

class LayoutNode {
  final String id;
  String type;
  Map<String, dynamic> properties;
  List<LayoutNode> children;

  /// Main Constructor
  LayoutNode({
    String? id,
    required this.type,
    Map<String, dynamic>? properties,
    List<LayoutNode>? children,
  }) : id = id ?? const Uuid().v4(),
       properties = properties ?? {},
       children = children ?? [];

  /// Deserialization from JSON (Recursive)
  factory LayoutNode.fromJson(Map<String, dynamic> json) {
    return LayoutNode(
      id: json['id'] as String?,
      type: json['type'] as String,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      children:
          (json['children'] as List<dynamic>?)
              ?.map(
                (childJson) =>
                    LayoutNode.fromJson(childJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Serialization to JSON (Recursive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'properties': properties,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  /// Helper Method for the Undo/Redo Engine
  LayoutNode clone() {
    return LayoutNode.fromJson(toJson());
  }

  /// Task 1 & 2: Recursive Parsing Engine & Dynamic Indentation Tracker
  /// Translates the JSON tree into standard, readable Flutter widgets.
  String toDartCode({int indentLevel = 0, bool isRoot = false}) {
    String getIndent(int level) => '  ' * level;

    int currentLevel = indentLevel;
    String prefix = '';
    String suffix = '';

    // 1. Boundary Protection (Expanded wrapper)
    // If it is not the root, it must be wrapped in an Expanded widget for proportional sizing.
    if (!isRoot) {
      final flexValue = properties['flex_value'] as int? ?? 1000;
      prefix += '${getIndent(currentLevel)}Expanded(\n';
      prefix += '${getIndent(currentLevel + 1)}flex: $flexValue,\n';
      prefix += '${getIndent(currentLevel + 1)}child: ';

      // Suffix closes the Expanded widget after the core content is generated
      suffix = '\n${getIndent(currentLevel)}),\n' + suffix;
      currentLevel += 1;
    } else {
      // The root layer does not get an Expanded wrapper
      prefix += getIndent(currentLevel);
      suffix = ',\n';
    }

    // 2. Viewport Mapping (LockEdit wrapper)
    final isLocked = properties['is_locked'] == true;
    if (isLocked) {
      prefix += 'SingleChildScrollView(\n';
      prefix += '${getIndent(currentLevel + 1)}child: ';

      // Suffix closes the ScrollView
      suffix = '\n${getIndent(currentLevel)}),' + suffix;
      currentLevel += 1;
    }

    // 3. Structural Mapping (Core Widget)
    if (type == 'RowNode' || type == 'ColumnNode') {
      final widgetName = type == 'RowNode' ? 'Row' : 'Column';
      prefix += '$widgetName(\n';
      prefix +=
          '${getIndent(currentLevel + 1)}crossAxisAlignment: CrossAxisAlignment.stretch,\n';
      prefix += '${getIndent(currentLevel + 1)}children: [\n';

      // Recursively parse all children, increasing the indentation level
      for (var child in children) {
        prefix += child.toDartCode(
          indentLevel: currentLevel + 2,
          isRoot: false,
        );
      }

      prefix += '${getIndent(currentLevel + 1)}],';
      prefix += '\n${getIndent(currentLevel)})';
    } else {
      // 4. Leaf Node Mapping (The empty containers)
      final layerName = properties['layer_name'] ?? 'Placeholder';
      prefix += 'Container(\n';
      prefix += '${getIndent(currentLevel + 1)}color: Colors.grey.shade200,\n';
      prefix +=
          '${getIndent(currentLevel + 1)}child: const Center(child: Text(\'$layerName\')),';
      prefix += '\n${getIndent(currentLevel)})';
    }

    // Combine the prefixes and suffixes to output the final block
    return prefix + suffix;
  }
}
