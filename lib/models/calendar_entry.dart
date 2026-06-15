import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum EntryStatus { notStarted, inProgress, completed }

class TaskCompletion {
  final String taskId;
  final bool isCompleted;

  const TaskCompletion({required this.taskId, this.isCompleted = false});

  TaskCompletion copyWith({bool? isCompleted}) =>
      TaskCompletion(taskId: taskId, isCompleted: isCompleted ?? this.isCompleted);

  Map<String, dynamic> toJson() => {'taskId': taskId, 'isCompleted': isCompleted};

  factory TaskCompletion.fromJson(Map<String, dynamic> json) => TaskCompletion(
        taskId: json['taskId'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class CalendarEntry {
  final String id;
  final String blockId;
  final String blockName; // denormalized for display
  final String date; // 'YYYY-MM-DD'
  final int plannedStartMinutes; // minutes since midnight
  final int plannedDurationMinutes;
  final int? actualStartMinutes;
  final int? actualEndMinutes;
  final EntryStatus status;
  final List<TaskCompletion> taskCompletions;

  CalendarEntry({
    String? id,
    required this.blockId,
    required this.blockName,
    required this.date,
    required this.plannedStartMinutes,
    required this.plannedDurationMinutes,
    this.actualStartMinutes,
    this.actualEndMinutes,
    this.status = EntryStatus.notStarted,
    this.taskCompletions = const [],
  }) : id = id ?? _uuid.v4();

  String get plannedStartLabel {
    final h = plannedStartMinutes ~/ 60;
    final m = plannedStartMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get plannedEndLabel {
    final end = plannedStartMinutes + plannedDurationMinutes;
    final h = end ~/ 60;
    final m = end % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String? get actualStartLabel {
    if (actualStartMinutes == null) return null;
    final h = actualStartMinutes! ~/ 60;
    final m = actualStartMinutes! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String? get actualEndLabel {
    if (actualEndMinutes == null) return null;
    final h = actualEndMinutes! ~/ 60;
    final m = actualEndMinutes! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int get completedTaskCount => taskCompletions.where((t) => t.isCompleted).length;

  CalendarEntry copyWith({
    String? blockName,
    int? plannedStartMinutes,
    int? plannedDurationMinutes,
    int? actualStartMinutes,
    int? actualEndMinutes,
    EntryStatus? status,
    List<TaskCompletion>? taskCompletions,
  }) =>
      CalendarEntry(
        id: id,
        blockId: blockId,
        blockName: blockName ?? this.blockName,
        date: date,
        plannedStartMinutes: plannedStartMinutes ?? this.plannedStartMinutes,
        plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
        actualStartMinutes: actualStartMinutes ?? this.actualStartMinutes,
        actualEndMinutes: actualEndMinutes ?? this.actualEndMinutes,
        status: status ?? this.status,
        taskCompletions: taskCompletions ?? this.taskCompletions,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'blockId': blockId,
        'blockName': blockName,
        'date': date,
        'plannedStartMinutes': plannedStartMinutes,
        'plannedDurationMinutes': plannedDurationMinutes,
        'actualStartMinutes': actualStartMinutes,
        'actualEndMinutes': actualEndMinutes,
        'status': status.name,
        'taskCompletions': taskCompletions.map((t) => t.toJson()).toList(),
      };

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
        id: json['id'] as String,
        blockId: json['blockId'] as String,
        blockName: json['blockName'] as String,
        date: json['date'] as String,
        plannedStartMinutes: json['plannedStartMinutes'] as int,
        plannedDurationMinutes: json['plannedDurationMinutes'] as int,
        actualStartMinutes: json['actualStartMinutes'] as int?,
        actualEndMinutes: json['actualEndMinutes'] as int?,
        status: EntryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EntryStatus.notStarted,
        ),
        taskCompletions: (json['taskCompletions'] as List<dynamic>? ?? [])
            .map((t) => TaskCompletion.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
