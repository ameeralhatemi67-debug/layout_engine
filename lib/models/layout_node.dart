import 'dart:convert'; // Required for Deep Copying
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
       properties = _initializeProperties(properties),
       children = children ?? [];

  /// Task 1: Data Model Upgrade
  /// Injects new Pillar 2 default properties and detaches nested memory references.
  static Map<String, dynamic> _initializeProperties(
    Map<String, dynamic>? props,
  ) {
    final base = props != null
        ? Map<String, dynamic>.from(props)
        : <String, dynamic>{};

    // Inject Checkpoint 7 defaults if they do not exist yet
    base['padding'] =
        base['padding'] ?? {'top': 0, 'bottom': 0, 'left': 0, 'right': 0};
    base['padding_color'] = base['padding_color'] ?? 'light_orange';
    base['alignment'] = base['alignment'] ?? 'center';
    // base['locked_size'] remains null until explicitly set by a user

    // Detach nested padding map to prevent shallow-copy reference bugs
    if (base['padding'] is Map) {
      base['padding'] = Map<String, dynamic>.from(base['padding'] as Map);
    }

    return base;
  }

  /// Deserialization from JSON (Recursive)
  factory LayoutNode.fromJson(Map<String, dynamic> json) {
    return LayoutNode(
      id: json['id'] as String?,
      type: json['type'] as String,
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'])
          : {},
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

  /// Task 2: Serialization to JSON (Recursive) & Safe Deep Copy
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      // We encode and decode the properties to force a 100% clean Deep Copy of nested maps
      'properties': jsonDecode(jsonEncode(properties)),
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  /// Helper Method for the Undo/Redo Engine
  LayoutNode clone() {
    // We also force a deep copy here to guarantee the Memento history stack
    // never accidentally mutates past padding states.
    return LayoutNode.fromJson(jsonDecode(jsonEncode(toJson())));
  }

  /// Recursive Parsing Engine & Dynamic Indentation Tracker
  String toDartCode({int indentLevel = 0, bool isRoot = false}) {
    String getIndent(int level) => '  ' * level;

    int currentLevel = indentLevel;
    String prefix = '';
    String suffix = '';

    // 1. Boundary Protection (Expanded wrapper)
    if (!isRoot) {
      final flexValue = properties['flex_value'] as int? ?? 1000;
      prefix += '${getIndent(currentLevel)}Expanded(\n';
      prefix += '${getIndent(currentLevel + 1)}flex: $flexValue,\n';
      prefix += '${getIndent(currentLevel + 1)}child: ';

      suffix = '\n${getIndent(currentLevel)}),\n' + suffix;
      currentLevel += 1;
    } else {
      prefix += getIndent(currentLevel);
      suffix = ',\n';
    }

    // 2. Viewport Mapping (LockEdit wrapper)
    final isLocked = properties['is_locked'] == true;
    if (isLocked) {
      prefix += 'SingleChildScrollView(\n';
      prefix += '${getIndent(currentLevel + 1)}child: ';

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

    return prefix + suffix;
  }
}
