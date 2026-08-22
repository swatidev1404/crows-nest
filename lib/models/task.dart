class Task {
  final int? id;
  final int? blockId;
  final String title;
  final bool planned;
  final bool executed;
  final bool completedPlan;
  final bool completedExecution;

  Task({
    this.id,
    this.blockId,
    required this.title,
    this.planned = true,
    this.executed = false,
    this.completedPlan = false,
    this.completedExecution = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockId': blockId,
      'title': title,
      'planned': planned ? 1 : 0,
      'executed': executed ? 1 : 0,
      'completedPlan': completedPlan ? 1 : 0,
      'completedExecution': completedExecution ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      blockId: map['blockId'],
      title: map['title'],
      planned: map['planned'] == 1,
      executed: map['executed'] == 1,
      completedPlan: map['completedPlan'] == 1,
      completedExecution: map['completedExecution'] == 1,
    );
  }

  Task copyWith({
    int? id,
    int? blockId,
    String? title,
    bool? planned,
    bool? executed,
    bool? completedPlan,
    bool? completedExecution,
  }) {
    return Task(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      title: title ?? this.title,
      planned: planned ?? this.planned,
      executed: executed ?? this.executed,
      completedPlan: completedPlan ?? this.completedPlan,
      completedExecution: completedExecution ?? this.completedExecution,
    );
  }
}
