import 'package:crows_nest/models/task.dart';

class Block {
  final int? id;
  final String title;
  final String category;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int colorValue; // store Color.value
  final String? recurrence;

  // Not stored in the Block table directly, populated via join
  final List<Task> tasks;

  Block({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    this.recurrence,
    this.tasks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'colorValue': colorValue,
      'recurrence': recurrence,
    };
  }

  factory Block.fromMap(Map<String, dynamic> map, {List<Task>? tasks}) {
    return Block(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      colorValue: map['colorValue'],
      recurrence: map['recurrence'],
      tasks: tasks ?? [],
    );
  }

  Block copyWith({
    int? id,
    String? title,
    String? category,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? colorValue,
    String? recurrence,
    List<Task>? tasks,
  }) {
    return Block(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorValue: colorValue ?? this.colorValue,
      recurrence: recurrence ?? this.recurrence,
      tasks: tasks ?? this.tasks,
    );
  }
}
