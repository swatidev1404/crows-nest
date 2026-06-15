import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Task {
  final String id;
  final String blockId;
  final String title;

  Task({
    String? id,
    required this.blockId,
    required this.title,
  }) : id = id ?? _uuid.v4();

  Task copyWith({String? blockId, String? title}) =>
      Task(id: id, blockId: blockId ?? this.blockId, title: title ?? this.title);

  Map<String, dynamic> toJson() => {'id': id, 'blockId': blockId, 'title': title};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        blockId: json['blockId'] as String,
        title: json['title'] as String,
      );
}

class Block {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final List<Task> tasks;

  Block({
    String? id,
    required this.name,
    this.description,
    this.icon,
    this.tasks = const [],
  }) : id = id ?? _uuid.v4();

  Block copyWith({
    String? name,
    String? description,
    String? icon,
    List<Task>? tasks,
  }) =>
      Block(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        tasks: tasks ?? this.tasks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory Block.fromJson(Map<String, dynamic> json) => Block(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        tasks: (json['tasks'] as List<dynamic>? ?? [])
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
