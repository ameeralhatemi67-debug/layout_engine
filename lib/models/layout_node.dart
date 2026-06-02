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
}
