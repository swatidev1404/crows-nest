import 'dart:convert';

class BlockBlueprint {
  final int? id;
  final String title;
  final String category;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int colorValue;
  final List<int> requiredTagIds;
  final List<int> excludedTagIds;

  BlockBlueprint({
    this.id,
    required this.title,
    required this.category,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
    this.requiredTagIds = const [],
    this.excludedTagIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'colorValue': colorValue,
      'requiredTagIds': jsonEncode(requiredTagIds),
      'excludedTagIds': jsonEncode(excludedTagIds),
    };
  }

  factory BlockBlueprint.fromMap(Map<String, dynamic> map) {
    return BlockBlueprint(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      startHour: map['startHour'],
      startMinute: map['startMinute'],
      endHour: map['endHour'],
      endMinute: map['endMinute'],
      colorValue: map['colorValue'],
      requiredTagIds: List<int>.from(jsonDecode(map['requiredTagIds'] ?? '[]')),
      excludedTagIds: List<int>.from(jsonDecode(map['excludedTagIds'] ?? '[]')),
    );
  }
}

class TaskBlueprint {
  final int? id;
  final int? blockBlueprintId;
  final String title;
  final List<int> requiredTagIds;
  final List<int> excludedTagIds;

  TaskBlueprint({
    this.id,
    this.blockBlueprintId,
    required this.title,
    this.requiredTagIds = const [],
    this.excludedTagIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockBlueprintId': blockBlueprintId,
      'title': title,
      'requiredTagIds': jsonEncode(requiredTagIds),
      'excludedTagIds': jsonEncode(excludedTagIds),
    };
  }

  factory TaskBlueprint.fromMap(Map<String, dynamic> map) {
    return TaskBlueprint(
      id: map['id'],
      blockBlueprintId: map['blockBlueprintId'],
      title: map['title'],
      requiredTagIds: List<int>.from(jsonDecode(map['requiredTagIds'] ?? '[]')),
      excludedTagIds: List<int>.from(jsonDecode(map['excludedTagIds'] ?? '[]')),
    );
  }
}
